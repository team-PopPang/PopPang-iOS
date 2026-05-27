import Core
import Domain
import Foundation
import Testing
@testable import AlertFeature

struct AlertFeatureTests {
    @Test
    func onAppearLoadsActivityAndKeywordListsLikeV0() async {
        let popupUsecase = MockPopupUsecase()
        let userUsecase = MockUserUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        DIContainer.shared.register(userUsecase, for: UserUsecaseProtocol.self)
        let compound = AlertFeatureCompound(userUuid: "user-123", nickname: "팝팡")

        let state = await reduceAll(compound, action: .onAppear)

        #expect(state.alertPopups.map(\.popupUuid) == ["alert-popup"])
        #expect(state.keywords.map(\.keyword) == ["성수", "전시"])
        #expect(state.isLoading == false)
        #expect(state.message == nil)
    }

    @Test
    func deletePopupRemovesActivityItemLikeV0() async {
        let popupUsecase = MockPopupUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        DIContainer.shared.register(MockUserUsecase(), for: UserUsecaseProtocol.self)
        let compound = AlertFeatureCompound(userUuid: "user-123", nickname: "팝팡")
        compound.state = AlertFeatureCompound.State(
            userUuid: "user-123",
            nickname: "팝팡",
            alertPopups: popupUsecase.alertPopups
        )

        let state = await reduceAll(compound, action: .deletePopup("alert-popup"))

        #expect(popupUsecase.removeAlertRequests.count == 1)
        #expect(popupUsecase.removeAlertRequests.first?.0 == "user-123")
        #expect(popupUsecase.removeAlertRequests.first?.1 == "alert-popup")
        #expect(state.alertPopups.isEmpty)
        #expect(state.message == nil)
    }

    @Test
    func addKeywordTrimsAndPersistsKeywordLikeV0() async {
        let userUsecase = MockUserUsecase()
        DIContainer.shared.register(MockPopupUsecase(), for: PopupUsecaseProtocol.self)
        DIContainer.shared.register(userUsecase, for: UserUsecaseProtocol.self)
        let compound = AlertFeatureCompound(userUuid: "user-123", nickname: "팝팡")

        let state = await reduceAll(compound, action: .addKeyword("  팝업  "))

        #expect(state.keywords.map(\.keyword) == ["팝업"])
        #expect(state.keywordText == "")
        #expect(userUsecase.addKeywordRequests.count == 1)
        #expect(userUsecase.addKeywordRequests.first?.0 == "user-123")
        #expect(userUsecase.addKeywordRequests.first?.1 == "팝업")
        #expect(state.message == nil)
    }

    @Test
    func toggleLikeOptimisticallyUpdatesActivityPopupLikeV0() async {
        let popupUsecase = MockPopupUsecase()
        DIContainer.shared.register(popupUsecase, for: PopupUsecaseProtocol.self)
        DIContainer.shared.register(MockUserUsecase(), for: UserUsecaseProtocol.self)
        let compound = AlertFeatureCompound(userUuid: "user-123", nickname: "팝팡")
        compound.state = AlertFeatureCompound.State(
            userUuid: "user-123",
            nickname: "팝팡",
            alertPopups: popupUsecase.alertPopups
        )

        let state = await reduceAll(compound, action: .toggleLike("alert-popup"))

        #expect(state.alertPopups.first?.isFavorited == true)
        #expect(state.alertPopups.first?.favoriteCount == 2)
        #expect(popupUsecase.addFavoriteRequests.count == 1)
        #expect(popupUsecase.addFavoriteRequests.first?.0 == "user-123")
        #expect(popupUsecase.addFavoriteRequests.first?.1 == "alert-popup")
        #expect(state.message == nil)
    }

    private func reduceAll(
        _ compound: AlertFeatureCompound,
        action: AlertFeatureCompound.Action,
        initialState: AlertFeatureCompound.State? = nil
    ) async -> AlertFeatureCompound.State {
        var state = initialState ?? compound.state

        for await reaction in compound.react(action: action) {
            state = compound.reduce(state: state, reaction: reaction)
        }

        return state
    }
}

private final class MockPopupUsecase: PopupUsecaseProtocol {
    private(set) var removeAlertRequests: [(String, String)] = []
    private(set) var addFavoriteRequests: [(String, String)] = []

    var alertPopups: [Popup] = [
        makePopup(id: "alert-popup", favoriteCount: 1, isFavorited: false),
    ]

    func getPopupList() async throws -> [Popup] { [] }
    func getUpcomingPopupList() async throws -> [Popup] { [] }
    func getInProgressPopupList() async throws -> [Popup] { [] }
    func getFavoriteList(userUuid: String) async throws -> [Popup] { [] }
    func searchPopupList(searchText: String) async throws -> [Popup] { [] }
    func getRandomPopupList() async throws -> [Popup] { [] }
    func getPersonalPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] { [] }
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] { [] }
    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] { [] }
    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] { [] }
    func increaseViewCount(popupUuid: String) async throws {}
    func removeFavorite(userUuid: String, popupUuid: String) async throws {}
    func getRegionList() async throws -> [RegionList] { [] }
    func getPopularRecommendList() async throws -> [Recommend] { [] }
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] { [] }

    func getAlertPopupList(userUuid: String) async throws -> [Popup] {
        alertPopups
    }

    func removeAlertPopup(userUuid: String, popupUuid: String) async throws {
        removeAlertRequests.append((userUuid, popupUuid))
    }

    func addFavorite(userUuid: String, popupUuid: String) async throws {
        addFavoriteRequests.append((userUuid, popupUuid))
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

private final class MockUserUsecase: UserUsecaseProtocol {
    private(set) var addKeywordRequests: [(String, String)] = []

    func checkNickname(nickname: String) async throws -> Bool { true }
    func getRecommandList() async throws -> [Recommend] { [] }
    func hardDeleteUser(userUuid: String) async throws {}
    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {}
    func alertStatus(userUuid: String, isAlerted: Bool) async throws {}
    func updateNickname(userUuid: String, newNickname: String) async throws {}
    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool { false }
    func updateFcmToken(userUuid: String, fcmToken: String) async throws {}

    func autoLogin(userUuid: String) async throws -> User {
        .adminUser
    }

    func getAlertKeywordList(userUuid: String) async throws -> [Keyword] {
        [Keyword(keyword: "성수"), Keyword(keyword: "전시")]
    }

    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        addKeywordRequests.append((userUuid, alertKeyword))
    }
}

private func makePopup(id: String, favoriteCount: Int, isFavorited: Bool) -> Popup {
    Popup(
        popupUuid: id,
        name: id,
        startDate: Date(timeIntervalSince1970: 1_000),
        endDate: Date(timeIntervalSince1970: 2_000),
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
        favoriteCount: favoriteCount,
        viewCount: 1,
        isFavorited: isFavorited,
        recommendList: []
    )
}
