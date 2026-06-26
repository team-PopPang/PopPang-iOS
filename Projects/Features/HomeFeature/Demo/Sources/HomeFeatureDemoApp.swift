import Domain
import HomeFeature
import SwiftUI

@main
struct HomeFeatureDemoApp: App {
    init() {
        DIContainer.shared.register(
            HomeFeatureDemoPopupUsecase(),
            for: PopupUsecaseProtocol.self
        )
    }

    var body: some Scene {
        WindowGroup {
            HomeFeatureView()
        }
    }
}

private final class HomeFeatureDemoPopupUsecase: PopupUsecaseProtocol {
    private var popups: [Popup] {
        [
            .popupMock,
            .popupMock2,
        ]
    }

    func getPopupList() async throws -> [Popup] {
        popups
    }

    func getUpcomingPopupList() async throws -> [Popup] {
        popups
    }

    func getInProgressPopupList() async throws -> [Popup] {
        popups
    }

    func getFavoriteList(userUuid: String) async throws -> [Popup] {
        popups.filter(\.isFavorited)
    }

    func searchPopupList(searchText: String) async throws -> [Popup] {
        popups
    }

    func getRandomPopupList() async throws -> [Popup] {
        popups
    }

    func getPersonalPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        popups
    }

    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] {
        popups
    }

    func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup] {
        popups
    }

    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] {
        popups.filter { $0.popupUuid != popupUuid }
    }

    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func getAlertPopupList(userUuid: String) async throws -> [Popup] {
        popups
    }

    func removeAlertPopup(userUuid: String, popupUuid: String) async throws {}

    func increaseViewCount(popupUuid: String) async throws {}

    func addFavorite(userUuid: String, popupUuid: String) async throws {}

    func removeFavorite(userUuid: String, popupUuid: String) async throws {}

    func getRegionList() async throws -> [RegionList] {
        [
            RegionList(region: "전체", districtList: ["전체"]),
            RegionList(region: "서울", districtList: ["전체", "강남구", "마포구", "성동구"]),
            RegionList(region: "부산", districtList: ["전체", "해운대구", "수영구"]),
        ]
    }

    func getPopularRecommendList() async throws -> [Recommend] {
        [
            Recommend(id: 1, recommendName: "패션"),
            Recommend(id: 2, recommendName: "디저트"),
            Recommend(id: 3, recommendName: "뷰티"),
        ]
    }

    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] {
        popups
    }
}
