import ComposableArchitecture
import Core
import Domain
import Foundation
import Testing
@testable import FavoritesFeature

@MainActor
struct FavoritesFeatureTests {
    @Test("하트를 누르면 응답을 기다리지 않고 숨기고, 성공하면 목록을 새로 받는다")
    func removeHidesImmediatelyAndReloadsAfterSuccess() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)

        await store.send(.favoritePopupsLoaded([.a, .b])) {
            $0.loadedPopups = [.a, .b]
            $0.favoritePopups = [.a, .b]
        }
        await store.send(.toggleLike(.a)) {
            $0.removingPopupUuids = ["a"]
            $0.favoritePopups = [.b]
        }

        await removals.respond("a", .success(()))
        await store.receive(\.removeFavoriteFinished) {
            $0.removingPopupUuids = []
            $0.loadedPopups = [.b]
        }
        await lists.respond(.success([.b]))
        await store.receive(\.favoritePopupsLoaded)
        await store.receive(\.loadingChanged)
        #expect(store.state.favoritePopups == [.b])
        #expect(store.state.errorMessage == nil)
    }

    @Test("해제 도중에 온 목록 응답에 해제 중인 팝업이 있어도 다시 보이지 않는다")
    func lateListResponseDoesNotBringBackRemovingPopup() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.send(.toggleLike(.a))

        // 하트를 누르기 전에 보낸 목록 요청의 응답이 늦게 온다.
        await lists.respond(.success([.a, .b]))
        await store.receive(\.favoritePopupsLoaded) {
            $0.loadedPopups = [.a, .b]
            $0.favoritePopups = [.b]
        }
        await store.receive(\.loadingChanged) {
            $0.isLoading = false
        }

        await removals.respond("a", .success(()))
        await store.receive(\.removeFavoriteFinished) {
            $0.removingPopupUuids = []
            $0.loadedPopups = [.b]
        }
        await lists.respond(.success([.b]))
        await store.receive(\.favoritePopupsLoaded)
        await store.receive(\.loadingChanged)
        #expect(store.state.favoritePopups == [.b])
    }

    @Test("연달아 해제하다 하나가 실패해도 아직 해제 중인 다른 팝업은 다시 보이지 않는다")
    func failedRemovalDoesNotBringBackOtherRemovingPopup() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)

        await store.send(.favoritePopupsLoaded([.a, .b]))
        await store.send(.toggleLike(.a))
        await store.send(.toggleLike(.b)) {
            $0.removingPopupUuids = ["a", "b"]
            $0.favoritePopups = []
        }

        await removals.respond("a", .failure(PopupError.failed))
        await store.receive(\.removeFavoriteFinished) {
            $0.removingPopupUuids = ["b"]
            $0.favoritePopups = [.a]
        }
        #expect(store.state.errorMessage != nil)

        // 실패 뒤 다시 받은 목록에는 아직 B가 있다.
        await lists.respond(.success([.a, .b]))
        await store.receive(\.favoritePopupsLoaded)
        await store.receive(\.loadingChanged)
        #expect(store.state.favoritePopups == [.a])

        await removals.respond("b", .success(()))
        await store.receive(\.removeFavoriteFinished) {
            $0.removingPopupUuids = []
            $0.loadedPopups = [.a]
        }
        await lists.respond(.success([.a]))
        await store.receive(\.favoritePopupsLoaded)
        await store.receive(\.loadingChanged)
        #expect(store.state.favoritePopups == [.a])
    }

    @Test("해제가 실패하면 팝업을 다시 보여 주고 안내 문구를 띄운 뒤 목록을 다시 받는다")
    func failedRemovalRestoresPopupAndReloads() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)

        await store.send(.favoritePopupsLoaded([.a]))
        await store.send(.toggleLike(.a)) {
            $0.favoritePopups = []
        }

        // 다른 화면에서 이미 해제해 404 4102가 온 경우
        await removals.respond("a", .failure(PopupError.failed))
        await store.receive(\.removeFavoriteFinished) {
            $0.removingPopupUuids = []
            $0.favoritePopups = [.a]
        }
        let message = store.state.errorMessage
        #expect(message != nil)

        await lists.respond(.success([]))
        await store.receive(\.favoritePopupsLoaded) {
            $0.loadedPopups = []
            $0.favoritePopups = []
        }
        await store.receive(\.loadingChanged)
        #expect(store.state.errorMessage == message)
    }

    @Test("로그인이 끊기면 팝업을 다시 보여 주고 목록은 다시 받지 않는다")
    func loginRequiredRestoresPopupWithoutReload() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)

        await store.send(.favoritePopupsLoaded([.a]))
        await store.send(.toggleLike(.a))

        await removals.respond("a", .failure(AuthSessionError.loginRequired))
        await store.receive(\.removeFavoriteFinished) {
            $0.removingPopupUuids = []
            $0.favoritePopups = [.a]
        }
        #expect(store.state.errorMessage != nil)
        #expect(await lists.callCount == 0)
    }

    @Test("해제 중인 팝업의 하트를 다시 눌러도 해제 요청은 한 번만 보낸다")
    func repeatedTapSendsOneRemoval() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)

        await store.send(.favoritePopupsLoaded([.a]))
        await store.send(.toggleLike(.a))
        await store.send(.toggleLike(.a))

        await removals.respond("a", .success(()))
        await store.receive(\.removeFavoriteFinished)
        await lists.respond(.success([]))
        await store.receive(\.favoritePopupsLoaded)
        await store.receive(\.loadingChanged)
        #expect(await removals.callCount == 1)
    }

    @Test("목록을 다시 받으면 목록 실패 문구는 지우고 해제 실패 문구는 남긴다")
    func successfulLoadClearsOnlyLoadFailure() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)

        await store.send(.onAppear)
        await lists.respond(.failure(PopupError.failed))
        await store.receive(\.errorMessageChanged)
        await store.receive(\.loadingChanged)
        #expect(store.state.errorMessage != nil)

        await store.send(.onAppear)
        await lists.respond(.success([.a]))
        await store.receive(\.favoritePopupsLoaded)
        await store.receive(\.loadingChanged)

        await store.send(.toggleLike(.a))
        await removals.respond("a", .failure(PopupError.failed))
        await store.receive(\.removeFavoriteFinished)
        let removeFailure = store.state.errorMessage
        #expect(removeFailure != nil)

        await lists.respond(.success([.a]))
        await store.receive(\.favoritePopupsLoaded)
        await store.receive(\.loadingChanged)
        #expect(store.state.errorMessage == removeFailure)
    }

    @Test("찜하지 않은 팝업의 하트를 눌러도 해제 요청을 보내지 않는다")
    func notFavoritedPopupIsNotRemoved() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)
        var popup = Popup.a
        popup.isFavorited = false

        await store.send(.favoritePopupsLoaded([popup]))
        await store.send(.toggleLike(popup))

        #expect(store.state.favoritePopups == [popup])
        #expect(await removals.callCount == 0)
    }

    @Test("목록을 받지 못하면 목록 실패 문구를 보여 준다")
    func failedLoadShowsMessage() async {
        let lists = Responses<[Popup]>()
        let removals = RemovalResponses()
        let store = makeStore(lists: lists, removals: removals)

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await lists.respond(.failure(PopupError.failed))
        await store.receive(\.errorMessageChanged)
        await store.receive(\.loadingChanged) {
            $0.isLoading = false
        }
        #expect(store.state.errorMessage != nil)
    }
}

// MARK: - 테스트 도구

@MainActor
private func makeStore(
    lists: Responses<[Popup]>,
    removals: RemovalResponses
) -> TestStoreOf<FavoritesFeature> {
    let store = TestStore(initialState: FavoritesFeature.State()) {
        FavoritesFeature()
    } withDependencies: {
        $0.favoritesFeatureClient = FavoritesFeatureClient(
            getFavoriteList: { try await lists.next() },
            removeFavorite: { popupUuid in try await removals.next(popupUuid) }
        )
    }
    // 화면용 파생 값(날짜별 개수 등)은 각 테스트에서 따로 확인하지 않는다.
    store.exhaustivity = .off(showSkippedAssertions: false)
    return store
}

/// 요청이 올 때까지 기다렸다가, 테스트가 정한 순서대로 응답을 돌려준다.
private actor Responses<Value: Sendable> {
    private var waiting: [CheckedContinuation<Result<Value, Error>, Never>] = []
    private var ready: [Result<Value, Error>] = []
    private(set) var callCount = 0

    func next() async throws -> Value {
        callCount += 1
        if !ready.isEmpty {
            return try ready.removeFirst().get()
        }
        return try await withCheckedContinuation { waiting.append($0) }.get()
    }

    /// 가장 먼저 기다린 요청에 응답한다. 아직 요청이 없으면 다음 요청에 쓴다.
    func respond(_ result: Result<Value, Error>) {
        if waiting.isEmpty {
            ready.append(result)
        } else {
            waiting.removeFirst().resume(returning: result)
        }
    }
}

/// 해제 요청을 팝업별로 기다렸다가, 테스트가 정한 순서대로 응답한다.
private actor RemovalResponses {
    private var responses: [String: Responses<Void>] = [:]
    private(set) var callCount = 0

    func next(_ popupUuid: String) async throws {
        callCount += 1
        try await responses(for: popupUuid).next()
    }

    func respond(_ popupUuid: String, _ result: Result<Void, Error>) async {
        await responses(for: popupUuid).respond(result)
    }

    private func responses(for popupUuid: String) -> Responses<Void> {
        if let existing = responses[popupUuid] { return existing }
        let created = Responses<Void>()
        responses[popupUuid] = created
        return created
    }
}

private extension Popup {
    static let a = make("a")
    static let b = make("b")

    static func make(_ popupUuid: String) -> Popup {
        Popup(
            popupUuid: popupUuid,
            name: "팝업 \(popupUuid)",
            startDate: Date(timeIntervalSince1970: 1_780_000_000),
            endDate: Date(timeIntervalSince1970: 1_780_500_000),
            openTime: nil,
            closeTime: nil,
            address: "서울 성동구",
            roadAddress: "서울 성동구",
            region: "서울",
            latitude: nil,
            longitude: nil,
            instaPostId: nil,
            instaPostUrl: nil,
            captionSummary: "",
            imageUrlList: [],
            mediaType: .image,
            favoriteCount: 0,
            viewCount: 0,
            isFavorited: true,
            recommendList: []
        )
    }
}
