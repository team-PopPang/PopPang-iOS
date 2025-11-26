//
//  CalendarViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/12/25.
//

import Foundation

final class CalendarViewModel: ObservableObject {
    let userUuid: String
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    
    // 서버에서 가져온 전체 팝업 리스트
    @Published var calendarPopups: [Popup] = []
    
    // 현재 선택된 날짜
    @Published var selectedDate: Date = Date()
    
    // 현재 선택된 날짜에 해당하는 팝업 목록
    @Published var selectedPopups: [Popup] = []
    
    // 날짜별 팝업 개수(캘린더 숫자 하단 표시용)
    @Published var popupEventCounts: [Date: Int] = [:]
    
    // 지역 시트 관련
    @Published var regions: [RegionList] = []
    @Published var selectedRegion: RegionList?
    @Published var selectedDistrict: String?
    
    // 정렬 시트 관련
    @Published var selectedOption: SortButton.SortOption = .newest
    
    init(userUuid: String) {
        self.userUuid = userUuid
        Task {
            await getAllPopupData()
        }
    }
}

// MARK: - 비동기 구조적 동시성
extension CalendarViewModel {
    func getAllPopupData() async {
        do {
            // MARK: - 지역 리스트는 리턴값이 다르므로 async let으로 병렬 실행(존재하지 않을때만 호출)
            if regions.isEmpty {
                async let regionTask = self.getRegionList()
                let regionList = await regionTask
                await MainActor.run {
                    self.regions = regionList
                    if let first = regionList.first {
                        self.selectedRegion = first
                        self.selectedDistrict = first.districtList.first
                    }
                }
            }
            
            try await withThrowingTaskGroup(of: (Int, [Popup]).self) { group in
                // 0, 1로 구분해서 요청
                group.addTask { (0, await self.getPersonalFilteredPopupList()) }
                
                for try await (index, popups) in group {
                    await MainActor.run {
                        switch index {
                        case 0:
                            self.calendarPopups = popups
                            self.calculateEventCounts()
                            self.selectDate(self.selectedDate)
                        default:
                            break
                        }
                    }
                }
            }
            Logger.d("캘린더 데이터 로드 완료")
        } catch {
            Logger.e("\(error)")
        }
    }
    
    // 필터링 초기 실행
    func getPersonalFilteredPopupList() async -> [Popup] {
        do {
            let popups =  try await popupUsecase.getPersonalFilteredPopupList(userUuid: userUuid,
                                                                              region: selectedRegion?.region ?? "전체",
                                                                              district: selectedDistrict ?? "전체",
                                                                              homeSortStandard: selectedOption.rawValue)
            return popups
        } catch {
            Logger.e("\(error)")
            return []
        }
    }
    
    // 필터링 업데이트
    func updatePersonalFilteredPopupList() async {
        do {
            let popups =  try await popupUsecase.getPersonalFilteredPopupList(userUuid: userUuid,
                                                                              region: selectedRegion?.region ?? "전체",
                                                                              district: selectedDistrict ?? "전체",
                                                                              homeSortStandard: selectedOption.rawValue)
            await MainActor.run {
                self.calendarPopups = popups
                self.calculateEventCounts()
                self.selectDate(self.selectedDate)
            }
        } catch {
            Logger.e("\(error)")
        }
    }
}

// MARK: - 캘린더 관련 메서드
extension CalendarViewModel {
    
    /// 팝업의 시작일~종료일을 순회하며 날짜별 이벤트 개수 집계하여 popupEventCounts에 저장
    /// - 팝업 기간이 10/15 ~ 10/17 이라면
    ///   - 10/15 → 1건
    ///   - 10/16 → 1건
    ///   - 10/17 → 1건
    private func calculateEventCounts() {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current
        
        for popup in calendarPopups {
            var date = calendar.startOfDay(for: popup.startDate)
            let end = calendar.startOfDay(for: popup.endDate)
            
            // 시작일부터 종료일까지 하루씩 순회하며 개수 증가
            while date <= end {
                counts[date, default: 0] += 1
                date = calendar.date(byAdding: .day, value: 1, to: date)!
            }
        }
        
        popupEventCounts = counts
    }
    
    
    /// 주어진 날짜가 특정 팝업의 시작일과 종료일 사이에 포함되는지 확인
    /// - Parameters:
    ///   - date: 검사할 대상 날짜
    ///   - start: 팝업 시작일
    ///   - end: 팝업 종료일
    /// - Returns: 날짜가 시작일과 종료일 사이에 포함되면 true, 아니면 false
    private func isDate(_ date: Date, between start: Date, and end: Date) -> Bool {
        let cal = Calendar.current
        let s = cal.startOfDay(for: start)
        let e = cal.startOfDay(for: end)
        let t = cal.startOfDay(for: date)
        return t >= s && t <= e
    }
    
    /// 사용자가 캘린더에서 특정 날짜를 선택하면 호출
    /// 선택된 날짜를 selectedData로 업데이트
    /// 현재 날짜에 포함되는 팝업들을 필터링 하여 selectedPopups에 저장
    /// - Parameter date: 사용자가 선택한 날짜
    func selectDate(_ date: Date) {
        selectedDate = date
        selectedPopups = calendarPopups.filter {
            isDate(date, between: $0.startDate, and: $0.endDate)
        }
    }
}

// MARK: - 찜 관련 메서드
extension CalendarViewModel {
    
    /// 팝업이 좋아요 눌린 상태인지 체크
    func isLiked(popup: Popup) -> Bool {
        return popup.isFavorited
    }
    
    /// 좋아요 상태 바꿔주는 함수
    func toggleLike(popup: Popup) async {
        do {
            let popupUuid = popup.popupUuid

            if popup.isFavorited {
                Logger.d("좋아요 취소")
                try await popupUsecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
                await MainActor.run {
                    // 전체 목록 갱신
                    if let index = self.calendarPopups.firstIndex(where: { $0.popupUuid == popupUuid }) {
                        
                        // 좋아요 취소
                        self.calendarPopups[index].isFavorited = false
                        
                        // 좋아요 -1
                        let count = self.calendarPopups[index].favoriteCount
                        self.calendarPopups[index].favoriteCount = max(0, count - 1)
                        
                    }
                    // 현재 선택된 날짜의 목록도 갱신
                    if let index = self.selectedPopups.firstIndex(where: { $0.popupUuid == popupUuid }) {
                        
                        // 좋아요 취소
                        self.selectedPopups[index].isFavorited = false
                        
                        // 좋아요 -1
                        let count = self.selectedPopups[index].favoriteCount
                        self.selectedPopups[index].favoriteCount = max(0, count - 1)
                    }
                }
            } else {
                Logger.d("좋아요 추가")
                try await popupUsecase.addFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                await MainActor.run {
                    // 전체 목록 갱신
                    if let index = self.calendarPopups.firstIndex(where: { $0.popupUuid == popupUuid }) {
                        
                        // 좋아요 추가
                        self.calendarPopups[index].isFavorited = true
                        
                        // 좋아요 +1
                        self.calendarPopups[index].favoriteCount += 1
                    }
                    // 현재 선택된 날짜의 목록도 갱신
                    if let index = self.selectedPopups.firstIndex(where: { $0.popupUuid == popupUuid }) {
                        self.selectedPopups[index].isFavorited = true
                        self.selectedPopups[index].favoriteCount += 1
                    }
                }
            }
        } catch {
            Logger.e("\(error)")
        }
    }
}

// MARK: - 지역 시트 관련 메서드
extension CalendarViewModel {
    
    // MARK: - 지역 필터링 가져오기 비동기
    func getRegionList() async -> [RegionList] {
        do {
            let regionList = try await popupUsecase.getRegionList()
                .sorted { lhs, rhs in
                    // 전체를 1순위 서울을 2순위
                    if lhs.region == "전체" { return true }
                    if rhs.region == "전체" { return false }
                    if lhs.region == "서울" { return true }
                    if rhs.region == "서울" { return false }
                    return false
                }
            return regionList
        } catch {
            Logger.e("❌ 찜 목록 불러오기 오류: \(error)")
            return []
        }
    }
}
