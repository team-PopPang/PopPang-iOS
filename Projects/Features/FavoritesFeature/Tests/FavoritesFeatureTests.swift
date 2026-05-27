import Core
import Domain
import Foundation
import Testing
@testable import FavoritesFeature

struct FavoritesFeatureTests {
    @Test
    func onAppearLoadsFavoriteListAndCalendarStateLikeV0() async {
        let popupUsecase = MockPopupUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        let compound = FavoritesFeatureCompound(userUuid: "user-123")

        let state = await reduceAll(compound, action: .onAppear)

        #expect(state.favoritePopups.map(\.popupUuid) == ["favorite-one", "favorite-two"])
        #expect(state.popupEventCounts[day(2026, 5, 27)] == 1)
        #expect(state.popupEventCounts[day(2026, 5, 28)] == 2)
        #expect(state.selectedPopups.map(\.popupUuid) == ["favorite-one"])
        #expect(state.isLoading == false)
        #expect(state.errorMessage == nil)
    }

    @Test
    func dateSelectionFiltersFavoritePopupsLikeV0Calendar() async {
        let popupUsecase = MockPopupUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        let compound = FavoritesFeatureCompound(userUuid: "user-123")
        compound.state = FavoritesFeatureCompound.State(
            userUuid: "user-123",
            favoritePopups: popupUsecase.favoritePopups
        )

        let state = await reduceAll(compound, action: .dateSelected(day(2026, 5, 29)))

        #expect(state.selectedDate == day(2026, 5, 29))
        #expect(state.selectedPopups.map(\.popupUuid) == ["favorite-two"])
    }

    @Test
    func toggleLikeRemovesFavoriteAndRefreshesCalendarStateLikeV0() async {
        let popupUsecase = MockPopupUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        let compound = FavoritesFeatureCompound(userUuid: "user-123")
        let popup = popupUsecase.favoritePopups[0]

        let state = await reduceAll(compound, action: .toggleLike(popup))

        #expect(popupUsecase.removeFavoriteRequests.count == 1)
        #expect(popupUsecase.removeFavoriteRequests.first?.0 == "user-123")
        #expect(popupUsecase.removeFavoriteRequests.first?.1 == "favorite-one")
        #expect(state.favoritePopups.map(\.popupUuid) == ["favorite-two"])
        #expect(state.popupEventCounts[day(2026, 5, 27)] == nil)
        #expect(state.isLoading == false)
    }

    private func reduceAll(
        _ compound: FavoritesFeatureCompound,
        action: FavoritesFeatureCompound.Action,
        initialState: FavoritesFeatureCompound.State? = nil
    ) async -> FavoritesFeatureCompound.State {
        var state = initialState ?? compound.state

        for await reaction in compound.react(action: action) {
            state = compound.reduce(state: state, reaction: reaction)
        }

        return state
    }
}

private final class MockPopupUsecase: PopupUsecaseProtocol {
    private(set) var removeFavoriteRequests: [(String, String)] = []

    var favoritePopups: [Popup] = [
        makePopup(id: "favorite-one", start: day(2026, 5, 27), end: day(2026, 5, 28)),
        makePopup(id: "favorite-two", start: day(2026, 5, 28), end: day(2026, 5, 29)),
    ]

    func getPopupList() async throws -> [Popup] { [] }
    func getUpcomingPopupList() async throws -> [Popup] { [] }
    func getInProgressPopupList() async throws -> [Popup] { [] }
    func searchPopupList(searchText: String) async throws -> [Popup] { [] }
    func getRandomPopupList() async throws -> [Popup] { [] }
    func getPersonalPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] { [] }
    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] { [] }
    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getAlertPopupList(userUuid: String) async throws -> [Popup] { [] }
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws {}
    func increaseViewCount(popupUuid: String) async throws {}
    func addFavorite(userUuid: String, popupUuid: String) async throws {}
    func getRegionList() async throws -> [RegionList] { [] }
    func getPopularRecommendList() async throws -> [Recommend] { [] }
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] { [] }

    func getFavoriteList(userUuid: String) async throws -> [Popup] {
        favoritePopups
    }

    func removeFavorite(userUuid: String, popupUuid: String) async throws {
        removeFavoriteRequests.append((userUuid, popupUuid))
        favoritePopups.removeAll { $0.popupUuid == popupUuid }
    }

    func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        []
    }

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
}

private func makePopup(id: String, start: Date, end: Date) -> Popup {
    Popup(
        popupUuid: id,
        name: id,
        startDate: start,
        endDate: end,
        openTime: "",
        closeTime: "",
        address: "주소",
        roadAddress: "서울 성동구",
        region: "서울",
        latitude: 37.0,
        longitude: 127.0,
        instaPostId: id,
        instaPostUrl: "https://instagram.com/p/\(id)",
        captionSummary: "요약",
        imageUrlList: [],
        mediaType: .image,
        favoriteCount: 1,
        viewCount: 1,
        isFavorited: true,
        recommendList: []
    )
}

private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
    Calendar.current.startOfDay(
        for: DateComponents(calendar: Calendar.current, year: year, month: month, day: day).date!
    )
}
