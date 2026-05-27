import Core
import Domain
import Foundation
import Testing
@testable import SearchFeature

struct SearchFeatureTests {
    @Test
    func searchTextInputUpdatesStateBeforeDebouncedSearchLikeV0() async {
        registerPopupUsecase()
        let compound = SearchFeatureCompound(userUuid: "user-123", recentSearchStorage: makeStorage())
        var state = compound.state
        var iterator = compound.react(action: .searchTextChanged("성수")).makeAsyncIterator()

        guard let searchTextReaction = await iterator.next() else {
            Issue.record("Expected search text reaction")
            return
        }
        state = compound.reduce(state: state, reaction: searchTextReaction)

        guard let loadingReaction = await iterator.next() else {
            Issue.record("Expected loading reaction")
            return
        }
        state = compound.reduce(state: state, reaction: loadingReaction)

        #expect(state.searchText == "성수")
        #expect(state.isLoading)
    }

    @Test
    func emptySearchTextClearsResultsAndErrorLikeV0() async {
        registerPopupUsecase()
        let compound = SearchFeatureCompound(userUuid: "user-123", recentSearchStorage: makeStorage())
        let previousState = SearchFeatureCompound.State(
            searchText: "성수",
            recentKeywords: ["성수"],
            searchPopupList: [.popupMock],
            isLoading: true,
            errorMessage: "network"
        )

        let state = await reduceAll(
            compound,
            action: .searchTextChanged(""),
            initialState: previousState
        )

        #expect(state.searchText.isEmpty)
        #expect(state.searchPopupList.isEmpty)
        #expect(state.errorMessage == nil)
        #expect(state.isLoading == false)
    }

    @Test
    func onAppearLoadsRecentKeywordsLikeV0UserDefaultsManagerLoad() async {
        registerPopupUsecase()
        let storage = makeStorage(testName: "onAppearLoadsRecentKeywordsLikeV0UserDefaultsManagerLoad")
        storage.add("성수")
        storage.add("홍대")
        let compound = SearchFeatureCompound(userUuid: "user-123", recentSearchStorage: storage)

        let state = await reduceAll(compound, action: .onAppear)

        #expect(state.recentKeywords == ["홍대", "성수"])
    }

    @Test
    func recentKeywordRemovalUpdatesStorageAndStateLikeV0() async {
        registerPopupUsecase()
        let storage = makeStorage(testName: "recentKeywordRemovalUpdatesStorageAndStateLikeV0")
        storage.add("성수")
        storage.add("홍대")
        storage.add("잠실")
        let compound = SearchFeatureCompound(userUuid: "user-123", recentSearchStorage: storage)

        let state = await reduceAll(compound, action: .recentKeywordRemoved("홍대"))

        #expect(state.recentKeywords == ["잠실", "성수"])
        #expect(storage.load() == ["잠실", "성수"])
    }

    private func registerPopupUsecase() {
        DIContainer.shared.register(MockPopupUsecase(), for: PopupUsecaseProtocol.self)
    }

    private func makeStorage(testName: String = #function) -> RecentSearchStorage {
        let suiteName = "SearchFeatureTests.\(testName)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        return RecentSearchStorage(store: UserDefaultsStore(userDefaults: userDefaults))
    }

    private func reduceAll(
        _ compound: SearchFeatureCompound,
        action: SearchFeatureCompound.Action,
        initialState: SearchFeatureCompound.State? = nil
    ) async -> SearchFeatureCompound.State {
        var state = initialState ?? compound.state

        for await reaction in compound.react(action: action) {
            state = compound.reduce(state: state, reaction: reaction)
        }

        return state
    }
}

private struct MockPopupUsecase: PopupUsecaseProtocol {
    func getPopupList() async throws -> [Popup] { [] }
    func getUpcomingPopupList() async throws -> [Popup] { [] }
    func getInProgressPopupList() async throws -> [Popup] { [] }
    func getFavoriteList(userUuid: String) async throws -> [Popup] { [] }
    func searchPopupList(searchText: String) async throws -> [Popup] { [] }
    func getRandomPopupList() async throws -> [Popup] { [] }
    func getPersonalPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] { [] }

    func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        []
    }

    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] {
        [.popupMock]
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

    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] { [] }
    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getAlertPopupList(userUuid: String) async throws -> [Popup] { [] }
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws {}
    func increaseViewCount(popupUuid: String) async throws {}
    func addFavorite(userUuid: String, popupUuid: String) async throws {}
    func removeFavorite(userUuid: String, popupUuid: String) async throws {}
    func getRegionList() async throws -> [RegionList] { [] }
    func getPopularRecommendList() async throws -> [Recommend] { [] }
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] { [] }
}
