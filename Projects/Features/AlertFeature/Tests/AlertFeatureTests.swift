import ComposableArchitecture
import Core
import Domain
import Foundation
import Testing
@testable import AlertFeature

@MainActor
struct AlertFeatureTests {
    @Test("들어오면 사용자 UUID 없이 알림함과 키워드를 받는다")
    func onAppearLoadsPopupsAndKeywords() async {
        let store = makeStore {
            $0.getAlertPopupList = { [.a] }
            $0.getAlertKeywordList = { [Keyword(keyword: "캐릭터")] }
            $0.loadRecentKeywords = { ["전시"] }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.initialDataLoaded) {
            $0.alertPopups = [.a]
            $0.keywords = [Keyword(keyword: "캐릭터")]
            $0.recentKeywords = ["전시"]
        }
        await store.receive(\.errorMessageChanged)
        await store.receive(\.loadingChanged) {
            $0.isLoading = false
        }
    }

    @Test("키워드만 실패해도 받은 알림함은 보여 주고 안내 문구를 띄운다")
    func keywordFailureStillShowsPopups() async {
        let store = makeStore {
            $0.getAlertPopupList = { [.a] }
            $0.getAlertKeywordList = { throw AlertKeywordError.failed }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.initialDataLoaded) {
            $0.alertPopups = [.a]
        }
        await store.receive(\.errorMessageChanged) {
            $0.errorMessage = "알림을 불러오지 못했어요. 잠시 후 다시 시도해 주세요."
        }
        await store.receive(\.loadingChanged) {
            $0.isLoading = false
        }
    }

    @Test("다시 로그인해야 하는 실패는 문구를 띄우지 않는다")
    func loginRequiredShowsNoMessage() async {
        let store = makeStore {
            $0.getAlertPopupList = { throw AuthSessionError.loginRequired }
            $0.getAlertKeywordList = { [] }
        }

        await store.send(.onAppear) {
            $0.isLoading = true
        }
        await store.receive(\.initialDataLoaded)
        await store.receive(\.errorMessageChanged)
        await store.receive(\.loadingChanged) {
            $0.isLoading = false
        }
        #expect(store.state.errorMessage == nil)
    }

    @Test("알림을 지우면 그 팝업 UUID로 요청하고 목록에서 뺀다")
    func deletePopupSendsPopupUuid() async {
        let removed = LockIsolated<[String]>([])
        let store = makeStore(popups: [.a, .b]) {
            $0.removeAlertPopup = { popupUuid in removed.withValue { $0.append(popupUuid) } }
        }

        await store.send(.deletePopupTapped("a")) {
            $0.deletingPopupUuids = ["a"]
        }
        await store.receive(\.deletePopupResponse) {
            $0.deletingPopupUuids = []
            $0.alertPopups = [.b]
        }
        #expect(removed.value == ["a"])
    }

    @Test("삭제 응답 전에 같은 알림을 다시 지우거나 전체 삭제를 다시 눌러도 요청을 다시 보내지 않는다")
    func deleteTapIsIgnoredWhileInFlight() async {
        let gate = AsyncGate()
        let removed = LockIsolated<[String]>([])
        let store = makeStore(popups: [.a]) {
            $0.removeAlertPopup = { popupUuid in
                removed.withValue { $0.append(popupUuid) }
                await gate.wait()
            }
        }

        await store.send(.deletePopupTapped("a")) {
            $0.deletingPopupUuids = ["a"]
        }
        await store.send(.deletePopupTapped("a"))
        await store.send(.deleteAllPopupsTapped)

        await gate.open()
        await store.receive(\.deletePopupResponse) {
            $0.deletingPopupUuids = []
            $0.alertPopups = []
        }
        #expect(removed.value == ["a"])
    }

    @Test("전체 삭제가 중간에 실패하면 그때까지 지운 알림만 빼고, 그사이 새로 받은 알림은 남긴다")
    func deleteAllRemovesOnlyDeletedPopups() async {
        let store = makeStore(popups: [.a, .b]) {
            $0.removeAlertPopup = { popupUuid in
                if popupUuid == "b" { throw PopupError.failed }
            }
        }

        await store.send(.deleteAllPopupsTapped) {
            $0.deletingPopupUuids = ["a", "b"]
        }
        await store.receive(\.deleteAllPopupsFinished) {
            $0.deletingPopupUuids = []
            $0.alertPopups = [.b]
            $0.errorMessage = "알림을 지우지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }

    @Test("키워드 요청 응답 전에는 같은 키워드의 삭제·등록을 다시 보내지 않는다")
    func keywordTapIsIgnoredWhileInFlight() async {
        let gate = AsyncGate()
        let removedCount = LockIsolated(0)
        let keyword = Keyword(keyword: "캐릭터")
        let store = makeStore {
            $0.removeAlertKeyword = { _ in
                removedCount.withValue { $0 += 1 }
                await gate.wait()
            }
        }
        await store.send(.initialDataLoaded(nil, [keyword], [])) {
            $0.keywords = [keyword]
        }

        await store.send(.removeKeywordTapped(keyword)) {
            $0.keywords = []
            $0.updatingKeywords = ["캐릭터"]
        }
        await store.send(.addKeywordTapped("캐릭터"))

        await gate.open()
        await store.receive(\.removeKeywordResponse) {
            $0.updatingKeywords = []
        }
        #expect(removedCount.value == 1)
    }

    @Test("찜 응답 전에 같은 하트를 다시 누르면 요청을 다시 보내지 않는다")
    func favoriteTapIsIgnoredWhileInFlight() async {
        let gate = AsyncGate()
        let added = LockIsolated<[String]>([])
        let store = makeStore(popups: [.a]) {
            $0.addFavorite = { popupUuid in
                added.withValue { $0.append(popupUuid) }
                await gate.wait()
            }
        }

        await store.send(.toggleLikeTapped("a")) {
            $0.favoriteUpdatingPopupUuids = ["a"]
            $0.alertPopups[0].isFavorited = true
            $0.alertPopups[0].favoriteCount = 1
        }
        await store.send(.toggleLikeTapped("a"))

        await gate.open()
        await store.receive(\.toggleLikeResponse) {
            $0.favoriteUpdatingPopupUuids = []
        }
        #expect(added.value == ["a"])
    }

    @Test("찜이 실패하면 하트를 되돌리고 안내 문구를 보여 준다")
    func favoriteFailureRestoresPopup() async {
        let store = makeStore(popups: [.a]) {
            $0.addFavorite = { _ in throw PopupError.failed }
        }

        await store.send(.toggleLikeTapped("a")) {
            $0.favoriteUpdatingPopupUuids = ["a"]
            $0.alertPopups[0].isFavorited = true
            $0.alertPopups[0].favoriteCount = 1
        }
        await store.receive(\.toggleLikeResponse) {
            $0.favoriteUpdatingPopupUuids = []
            $0.alertPopups = [.a]
            $0.errorMessage = "찜을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }

    @Test("서버에 이미 있는 키워드라는 응답이면 목록에 남기고 문구를 띄우지 않는다")
    func addExistingKeywordKeepsIt() async {
        let store = makeStore {
            $0.addAlertKeyword = { _ in throw AlertKeywordError.alreadyExists }
        }

        await store.send(.addKeywordTapped(" 캐릭터 ")) {
            $0.keywords = [Keyword(keyword: "캐릭터")]
            $0.updatingKeywords = ["캐릭터"]
        }
        await store.receive(\.addKeywordResponse) {
            $0.updatingKeywords = []
        }
        #expect(store.state.keywords == [Keyword(keyword: "캐릭터")])
        #expect(store.state.errorMessage == nil)
    }

    @Test("키워드 등록이 실패하면 목록에서 빼고 안내 문구를 보여 준다")
    func addKeywordFailureRemovesIt() async {
        let sent = LockIsolated<[String]>([])
        let store = makeStore {
            $0.addAlertKeyword = { keyword in
                sent.withValue { $0.append(keyword) }
                throw AlertKeywordError.failed
            }
        }

        await store.send(.addKeywordTapped("캐릭터")) {
            $0.keywords = [Keyword(keyword: "캐릭터")]
            $0.updatingKeywords = ["캐릭터"]
        }
        await store.receive(\.addKeywordResponse) {
            $0.updatingKeywords = []
            $0.keywords = []
            $0.errorMessage = "키워드를 등록하지 못했어요. 잠시 후 다시 시도해 주세요."
        }
        #expect(sent.value == ["캐릭터"])
    }

    @Test("키워드 삭제가 실패하면 목록에 되돌리고 안내 문구를 보여 준다")
    func removeKeywordFailureRestoresIt() async {
        let keyword = Keyword(keyword: "캐릭터")
        let store = makeStore {
            $0.removeAlertKeyword = { _ in throw AlertKeywordError.failed }
        }
        await store.send(.initialDataLoaded([], [keyword], [])) {
            $0.keywords = [keyword]
        }

        await store.send(.removeKeywordTapped(keyword)) {
            $0.keywords = []
            $0.updatingKeywords = ["캐릭터"]
        }
        await store.receive(\.removeKeywordResponse) {
            $0.updatingKeywords = []
            $0.keywords = [keyword]
            $0.errorMessage = "키워드를 지우지 못했어요. 잠시 후 다시 시도해 주세요."
        }
    }
}

private func makeStore(
    popups: [Popup] = [],
    configure: (inout AlertFeatureClient) -> Void
) -> TestStoreOf<AlertFeature> {
    var initialState = AlertFeature.State(user: .fixture)
    initialState.alertPopups = popups
    var client = AlertFeatureClient.unimplemented
    configure(&client)
    return TestStore(initialState: initialState) {
        AlertFeature()
    } withDependencies: {
        $0.alertFeatureClient = client
    }
}

/// 테스트가 열 때까지 요청을 붙잡아 둔다.
private actor AsyncGate {
    private var isOpen = false
    private var waiting: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { waiting.append($0) }
    }

    func open() {
        isOpen = true
        waiting.forEach { $0.resume() }
        waiting.removeAll()
    }
}

private extension User {
    static var fixture: User {
        User(userUuid: "user-1", provider: .kakao, email: nil, nickname: "팝팡", role: .member, isAlerted: true)
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
            isFavorited: false,
            recommendList: []
        )
    }
}
