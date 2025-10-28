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
    @Published var isLoaded: Bool = false
    
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
            await self.getFavoriteList()
            await self.getAllPopupData()
            await self.fetchRegionList()
            await MainActor.run {
                self.isLoaded = true
            }
        }
    }
}

// MARK: - 팝업 전체 불러오기
extension HomeViewModel {
    func getAllPopupData() async {
        do {
            try await withThrowingTaskGroup(of: (Int, [Popup]).self) {  group in
                // 0, 1, 2로 구분해서 요청
                group.addTask { (0, try await self.popupUsecase.getPopupList()) }
                group.addTask { (1, try await self.popupUsecase.getUpcomingPopupList()) }
                group.addTask { (2, try await self.popupUsecase.getPopupList()) }

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
        } catch {
            print("❌ 팝업 목록 불러오기 오류: \(error)")
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
                print("좋아요 취소")
                try await popupUsecase.removeFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                _ = await MainActor.run {
                    likePostIds.remove(popup.popupUuid)
                }
            } else {
                print("좋아요 추가")
                try await popupUsecase.addFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                _ = await MainActor.run {
                    likePostIds.insert(popup.popupUuid)
                }
            }
        } catch {
            print("❌ 찜 토글 실패:", error)
        }
    }
    
    func getFavoriteList() async {
        do {
            let favoritePopups = try await popupUsecase.getFavoriteList(userUuid: userUuid)
            await MainActor.run {
                likePostIds = Set(favoritePopups.map { $0.popupUuid })
            }
            print("좋아요한거: \(likePostIds)")
        } catch {
            print("❌ 찜 목록 불러오기 오류: \(error)")
        }
    }
}

// MARK: - 시트 관련 메서드
extension HomeViewModel {
    func fetchRegionList() async {
        // ⏳ 네트워크 대신 목업 데이터 (비동기 시뮬레이션)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초 지연
        
        let mockData: [RegionListDTO] = [
            RegionListDTO(region: "전체", districts: ["전체"]),
            RegionListDTO(region: "서울", districts: ["전체", "강남구", "성동구", "송파구", "종로구"]),
            RegionListDTO(region: "부산", districts: ["전체"]),
            RegionListDTO(region: "인천", districts: ["전체"]),
            RegionListDTO(region: "경기", districts: ["전체"]),
        ]
        
        let mapped = mockData.map { $0.toModel() }
        
        await MainActor.run {
            self.regions = mapped
            if let first = mapped.first {
                self.selectedRegion = first
                self.selectedDistrict = first.districts.first
            }
        }
    }
}
