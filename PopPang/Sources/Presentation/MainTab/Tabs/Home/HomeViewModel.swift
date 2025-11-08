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
    @Published var likePostIds: Set<String> = [] // 찜 목록 popupUuid
    // @Published var isLoaded: Bool = false
    
    // MARK: - 지역 시트 관련
    @Published var showRegionSheet: Bool = false
    @Published var regions: [RegionList] = []
    @Published var selectedRegion: RegionList?
    @Published var selectedDistrict: String?
    
    // MARK: - 정렬 시트 관련
    @Published var showSortSheet: Bool = false
    @Published var selectedOption: SortButton.SortOption = .favorite
    
    init(userUuid: String) {
        self.userUuid = userUuid
        
        Task {
            // await getAllPopupData() /// 3개 섹션 전체 팝업 가져오기
            /*
            await MainActor.run {
                self.isLoaded = true
            }
             */
        }
    }
}

// MARK: - 팝업 관련 메서드
extension HomeViewModel {
    
    // MARK: - 팝업 전체 가져오기 비동기
    func getAllPopupData() async {
        do {
            
            // MARK: - 지역 리스트는 리턴값이 다르므로 async let으로 병렬 실행
            async let regionTask = self.getRegionList()
            let regionList = await regionTask
            await MainActor.run {
                self.regions = regionList
                if let first = regionList.first {
                    self.selectedRegion = first
                    self.selectedDistrict = first.districtList.first
                }
            }
           
            // MARK: - 리턴값이 같은 팝업 관련 요청은 TaskGroup 안에서 벙렬 처리
            try await withThrowingTaskGroup(of: (Int, [Popup]).self) {  group in
                // 0, 1, 2로 구분해서 요청
                group.addTask { (0, try await self.popupUsecase.getPopupList()) }           // 첫 섹션
                group.addTask { (1, try await self.popupUsecase.getUpcomingPopupList()) }   // 두번쨰 섹션
                group.addTask { (2, try await self.popupUsecase.getInProgressPopupList()) } // 세번째 섹션
                group.addTask { (3, await self.getFavoriteList()) }                         // 찜 리스트를 가져와서 uuid만 배열로 가짐

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
                        case 3:
                            self.likePostIds = Set(popups.map { $0.popupUuid })
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
}

// MARK: - 찜 관련 메서드
extension HomeViewModel {
    
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
            Logger.e("❌ 찜 토글 실패:")
        }
    }
    
    // MARK: - 찜 항목 가져오기 비동기
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

// MARK: - 시트 관련 메서드
extension HomeViewModel {
    
    // MARK: - 지역 필터링 가져오기 비동기
    func getRegionList() async -> [RegionList] {
        do {
            let regionListDTO = try await popupUsecase.getRegionList()
            // Logger.d("지역 필터링 가져오기 성공")
            return regionListDTO
        } catch {
            Logger.e("❌ 찜 목록 불러오기 오류: \(error)")
            return []
        }
    }
}
