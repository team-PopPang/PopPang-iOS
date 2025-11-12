//
//  HomeViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    let userUuid: String
    
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var bestPopups: [Popup] = []
    @Published var comingPopups: [Popup] = []
    @Published var gridPopups: [Popup] = []
    
    // MARK: - 지역 시트 관련
    @Published var showRegionSheet: Bool = false
    @Published var regions: [RegionList] = []
    @Published var selectedRegion: RegionList?
    @Published var selectedDistrict: String?
    
    // MARK: - 정렬 시트 관련
    @Published var showSortSheet: Bool = false
    @Published var selectedOption: SortButton.SortOption = .newest
    
    init(userUuid: String) {
        self.userUuid = userUuid
    }
}

// MARK: - 팝업 리스트 비동기 함수
extension HomeViewModel {
    
    // MARK: - 팝업 전체 가져오기 비동기
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
           
            // MARK: - 리턴값이 같은 팝업 관련 요청은 TaskGroup 안에서 벙렬 처리
            try await withThrowingTaskGroup(of: (Int, [Popup]).self) {  group in
                
                // 0, 1, 2로 구분해서 요청
                group.addTask { (0, await self.getPersonalPopupList()) }
                group.addTask { (1, await self.getPersonalUpcomingPopupList()) }
                group.addTask { (2, await self.getPersonalFilteredPopupList()) }
                
                // 완료된 순서대로 결과 받기
                for try await (index, popups) in group {
                    await MainActor.run {
                        switch index {
                        case 0:
                            self.bestPopups = popups
                        case 1:
                            self.comingPopups = popups
                                .sorted { $0.startDate < $1.startDate }
                        case 2:
                            self.gridPopups = popups
                        default:
                            break
                        }
                    }
                }
            }
            Logger.d("홈뷰 데이터 로드 완료")
        } catch {
            Logger.e("❌ 팝업 목록 불러오기 오류: \(error)")
        }
    }
    
    // 첫 섹션
    func getPersonalPopupList() async -> [Popup] {
        do {
            let popups =  try await popupUsecase.getPersonalPopupList(userUuid: userUuid)
            return popups
        } catch {
            Logger.e("\(error)")
            return []
        }
    }
    
    // 두번쨰 섹션
    func getPersonalUpcomingPopupList() async -> [Popup] {
        do {
            let popups =  try await popupUsecase.getPersonalUpcomingPopupList(userUuid: userUuid)
            return popups
        } catch {
            Logger.e("\(error)")
            return []
        }
    }
    
    // 세번째 섹션
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
    
    // 세번째 섹션 업데이트
    func updatePersonalFilteredPopupList() async {
        do {
            let popups =  try await popupUsecase.getPersonalFilteredPopupList(userUuid: userUuid,
                                                                              region: selectedRegion?.region ?? "전체",
                                                                              district: selectedDistrict ?? "전체",
                                                                              homeSortStandard: selectedOption.rawValue)
            await MainActor.run {
                self.gridPopups = popups
            }
        } catch {
            Logger.e("\(error)")
            
        }
    }
}

// MARK: - 찜 관련 메서드
extension HomeViewModel {
    
    /// 팝업이 좋아요 눌린 상태인지 체크
    func isLiked(popup: Popup) -> Bool {
        popup.isFavorited
    }
    
    /// 좋아요 상태 바꿔주는 함수
    func toggleLike(popup: Popup) async {
        do {
            if popup.isFavorited {
                Logger.d("좋아요 취소")
                try await popupUsecase.removeFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                await MainActor.run {
                    if let index = self.gridPopups.firstIndex(where: { $0.popupUuid == popup.popupUuid }) {
                        self.gridPopups[index].isFavorited = false
                        
                        // 좋아요 수 감소
                        let count = self.gridPopups[index].favoriteCount
                        self.gridPopups[index].favoriteCount = max(0, count - 1)
                        
                    }
                }
            } else {
                Logger.d("좋아요 추가")
                try await popupUsecase.addFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                
                await MainActor.run {
                    if let index = self.gridPopups.firstIndex(where: { $0.popupUuid == popup.popupUuid }) {
                        self.gridPopups[index].isFavorited = true
                        
                        // 좋아요 수 증가
                        self.gridPopups[index].favoriteCount += 1
                    }
                }
            }
        } catch {
            Logger.e("❌ 찜 토글 실패:")
        }
    }
}

// MARK: - 지역 시트 관련 메서드
extension HomeViewModel {
    
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
