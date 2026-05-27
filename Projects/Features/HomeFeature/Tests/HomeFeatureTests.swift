import Core
import Domain
import DSKit
import Foundation
import Testing
@testable import HomeFeature

struct HomeFeatureTests {
    @Test
    func onAppearLoadsHomePopupListsLikeV0HomeViewModel() async {
        let popupUsecase = MockPopupUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        let compound = HomeFeatureCompound(userUuid: "user-123", nickname: "팝팡")

        let state = await reduceAll(compound, action: .onAppear)

        #expect(state.selectedRegion?.region == "전체")
        #expect(state.selectedDistrict == "전체")
        #expect(state.bestPopups.map(\.popupUuid) == ["best-popup"])
        #expect(state.comingPopups.map(\.popupUuid) == ["coming-soon", "coming-later"])
        #expect(state.gridPopups.map(\.popupUuid) == ["filtered-popup"])
        #expect(state.isLoading == false)
        #expect(state.errorMessage == nil)
    }

    @Test
    func districtSelectionRefreshesFilteredPopupListLikeV0() async {
        let popupUsecase = MockPopupUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        let compound = HomeFeatureCompound(userUuid: "user-123", nickname: "팝팡")
        compound.state = HomeFeatureCompound.State(
            userUuid: "user-123",
            nickname: "팝팡",
            regions: popupUsecase.regions,
            selectedRegion: RegionList(region: "서울", districtList: ["전체", "성동구"]),
            selectedDistrict: "전체"
        )

        let state = await reduceAll(compound, action: .districtSelected("성동구"))

        #expect(state.selectedDistrict == "성동구")
        #expect(state.gridPopups.map(\.popupUuid) == ["filtered-popup"])
        #expect(popupUsecase.filteredRequests.last?.region == "서울")
        #expect(popupUsecase.filteredRequests.last?.district == "성동구")
        #expect(popupUsecase.filteredRequests.last?.sort == SortButton.SortOption.newest.rawValue)
    }

    @Test
    func favoriteToggleUpdatesPopupStateLikeV0() async {
        let popupUsecase = MockPopupUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        var popup = Popup.popupMock
        popup.isFavorited = false
        popup.favoriteCount = 3
        let compound = HomeFeatureCompound(userUuid: "user-123", nickname: "팝팡")
        compound.state = HomeFeatureCompound.State(
            userUuid: "user-123",
            nickname: "팝팡",
            gridPopups: [popup]
        )

        let state = await reduceAll(compound, action: .toggleLike(popup))

        #expect(state.gridPopups.first?.isFavorited == true)
        #expect(state.gridPopups.first?.favoriteCount == 4)
        #expect(popupUsecase.addFavoriteRequests.count == 1)
        #expect(popupUsecase.addFavoriteRequests.first?.0 == "user-123")
        #expect(popupUsecase.addFavoriteRequests.first?.1 == popup.popupUuid)
    }

    private func reduceAll(
        _ compound: HomeFeatureCompound,
        action: HomeFeatureCompound.Action,
        initialState: HomeFeatureCompound.State? = nil
    ) async -> HomeFeatureCompound.State {
        var state = initialState ?? compound.state

        for await reaction in compound.react(action: action) {
            state = compound.reduce(state: state, reaction: reaction)
        }

        return state
    }
}

private final class MockPopupUsecase: PopupUsecaseProtocol {
    private(set) var filteredRequests: [(region: String, district: String, sort: String)] = []
    private(set) var addFavoriteRequests: [(String, String)] = []

    let regions = [
        RegionList(region: "부산", districtList: ["전체", "해운대구"]),
        RegionList(region: "서울", districtList: ["전체", "성동구"]),
        RegionList(region: "전체", districtList: ["전체"]),
    ]

    func getPopupList() async throws -> [Popup] { [] }
    func getUpcomingPopupList() async throws -> [Popup] { [] }
    func getInProgressPopupList() async throws -> [Popup] { [] }
    func getFavoriteList(userUuid: String) async throws -> [Popup] { [] }
    func searchPopupList(searchText: String) async throws -> [Popup] { [] }
    func getRandomPopupList() async throws -> [Popup] { [] }
    func getPersonalPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] { [] }

    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        [
            makePopup(id: "coming-later", startDate: Date(timeIntervalSince1970: 2_000)),
            makePopup(id: "coming-soon", startDate: Date(timeIntervalSince1970: 1_000)),
        ]
    }

    func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        filteredRequests.append((region, district, homeSortStandard))
        return [makePopup(id: "filtered-popup")]
    }

    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] { [] }

    func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup] {
        []
    }

    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] { [] }
    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] { [makePopup(id: "best-popup")] }
    func getAlertPopupList(userUuid: String) async throws -> [Popup] { [] }
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws {}
    func increaseViewCount(popupUuid: String) async throws {}

    func addFavorite(userUuid: String, popupUuid: String) async throws {
        addFavoriteRequests.append((userUuid, popupUuid))
    }

    func removeFavorite(userUuid: String, popupUuid: String) async throws {}
    func getRegionList() async throws -> [RegionList] { regions }
    func getPopularRecommendList() async throws -> [Recommend] { [] }
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] { [] }

    private func makePopup(id: String, startDate: Date = Date(timeIntervalSince1970: 1_000)) -> Popup {
        Popup(
            popupUuid: id,
            name: id,
            startDate: startDate,
            endDate: startDate.addingTimeInterval(86_400),
            openTime: "",
            closeTime: "",
            address: "주소",
            roadAddress: "도로명 주소",
            region: "서울",
            latitude: 37.0,
            longitude: 127.0,
            instaPostId: "insta",
            instaPostUrl: "https://instagram.com/p/\(id)",
            captionSummary: "요약",
            imageUrlList: [],
            mediaType: .image,
            favoriteCount: 0,
            viewCount: 0,
            isFavorited: false,
            recommendList: []
        )
    }
}
