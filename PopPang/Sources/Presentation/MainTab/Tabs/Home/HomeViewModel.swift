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
        
        Task { [weak self] in
            guard let self = self else { return }
            await self.getFavoriteList() /// 찜 항목 가져오기
            await self.getAllPopupData() /// 3개 섹션 전체 팝업 가져오기
            await self.getRegionList()   /// 지역 필터링 가져오기
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
            try await withThrowingTaskGroup(of: (Int, [Popup]).self) {  group in
                // 0, 1, 2로 구분해서 요청
                group.addTask { (0, try await self.popupUsecase.getPopupList()) }
                group.addTask { (1, try await self.popupUsecase.getUpcomingPopupList()) }
                group.addTask { (2, try await self.popupUsecase.getInProgressPopupList()) }

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
            Logger.d("팝업 전체 가져오기 성공")
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
    func getFavoriteList() async {
        do {
            let favoritePopups = try await popupUsecase.getFavoriteList(userUuid: userUuid)
            await MainActor.run {
                likePostIds = Set(favoritePopups.map { $0.popupUuid })
            }
            Logger.d("찜 팝업의 likePostIds 가져오기 성공")
        } catch {
            Logger.e("❌ 찜 목록 불러오기 오류: \(error)")
        }
    }
}

// MARK: - 시트 관련 메서드
extension HomeViewModel {
    
    // MARK: - 지역 필터링 가져오기 비동기
    func getRegionList() async {
        do {
            let regionListDTO = try await popupUsecase.getRegionList()
            await MainActor.run {
                self.regions = regionListDTO
                if let first = regionListDTO.first {
                    self.selectedRegion = first
                    self.selectedDistrict = first.districtList.first
                }
            }
            Logger.d("지역 필터링 가져오기 성공")
        } catch {
            Logger.e("❌ 찜 목록 불러오기 오류: \(error)")
        }
    }
}
