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
    
    // 찜 목록(내가 찜한 목록 색상 설정을 위함)
    @Published var likePostIds: Set<String> = []
    
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
            try await withThrowingTaskGroup(of: (Int, [Popup]).self) { group in
                // 0, 1로 구분해서 요청
                group.addTask { (0, await self.getCalendarPopupList()) }
                group.addTask { (1, await self.getFavoriteList()) }
                
                for try await (index, popups) in group {
                    await MainActor.run {
                        switch index {
                        case 0:
                            self.calendarPopups = popups
                            self.calculateEventCounts()
                            self.selectDate(self.selectedDate)
                        case 1:
                            likePostIds = Set(popups.map { $0.popupUuid })
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

// MARK: - 팝업 리스트 비동기 호출
extension CalendarViewModel {
    
    /// 서버에서 팝업 리스트 비동기 호출, 완료 후 날짜별 이벤트 개수 계산
    func getCalendarPopupList() async -> [Popup] {
        do {
            let popups =  try await popupUsecase.getPopupList()
            // Logger.d("캘린더 팝업 전체 가져오기 성공")
            return popups
        } catch {
            print("❌ getPopupList Error: \(error)")
            return []
        }
    }
}

// MARK: - 찜 관련 메서드
extension CalendarViewModel {
    
    /// 팝업이 좋아요 눌린 상태인지 체크
    func isLiked(popup: Popup) -> Bool {
        likePostIds.contains(popup.popupUuid)
    }
    
    /// 좋아요 상태 바꿔주는 함수
    func toggleLike(popup: Popup) async {
        do {
            if likePostIds.contains(popup.popupUuid) {
                Logger.d("좋아요 취소")
                try await popupUsecase.removeFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                _ = await MainActor.run {
                    likePostIds.remove(popup.popupUuid)
                }
            } else {
                Logger.d("좋아요 추가")
                try await popupUsecase.addFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                _ = await MainActor.run {
                    likePostIds.insert(popup.popupUuid)
                }
            }
        } catch {
            print("❌ 찜 토글 실패:", error)
        }
    }
    
    /// 찜한 팝업만 가져오는 함수
    func getFavoriteList() async -> [Popup] {
        do {
            let favoritePopups = try await popupUsecase.getFavoriteList(userUuid: userUuid)
            // Logger.d("찜 팝업 likePostIds 가져오기 성공")
            return favoritePopups
        } catch {
            Logger.e("❌ 찜 목록 불러오기 오류: \(error)")
            return []
        }
    }
}
