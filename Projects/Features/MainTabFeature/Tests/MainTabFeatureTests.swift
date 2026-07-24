import ComposableArchitecture
import Core
import Domain
import Testing
@testable import MainTabFeature

@MainActor
struct MainTabFeatureTests {
    @Test("HomeFeature의 검색 요청을 MainTabFeature가 SearchFeature presentation으로 연다")
    func presentsSearchFromHomeDelegate() async {
        let store = TestStore(initialState: MainTabFeature.State(session: makeSession())) {
            MainTabFeature()
        }
        store.exhaustivity = .off

        await store.send(.home(.delegate(.searchTapped)))

        guard case let .search(searchState)? = store.state.core.destination else {
            Issue.record("search destination should be presented")
            return
        }

        #expect(searchState.search.userUuid == "user-1")
        #expect(searchState.search.nickname == "팝팡")
    }

    @Test("HomeFeature의 팝업 제보 요청을 MainTabFeature가 RN presentation으로 연다")
    func presentsPopupRequestFromHomeDelegate() async {
        let store = TestStore(initialState: MainTabFeature.State(session: makeSession())) {
            MainTabFeature()
        }
        store.exhaustivity = .off

        await store.send(.home(.delegate(.popupRequestTapped)))

        guard case let .popupRequest(popupRequestState)? = store.state.core.destination else {
            Issue.record("popup request destination should be presented")
            return
        }

        #expect(popupRequestState.screen == .popupRequest)
        #expect(popupRequestState.userUuid == "user-1")
    }

    @Test("SearchFeature가 dismiss delegate를 보내면 MainTabFeature가 presentation을 닫는다")
    func clearsSearchDestinationWhenDismissed() async {
        var initialState = MainTabFeature.State(session: makeSession())
        initialState.core.destination = .search(
            .init(
                userUuid: "user-1",
                nickname: "팝팡"
            )
        )

        let store = TestStore(initialState: initialState) {
            MainTabFeature()
        }

        await store.send(.destination(.presented(.search(.delegate(.dismiss)))))

        await store.receive(\.searchDismissTeardownCompleted) {
            $0.core.destination = nil
        }
    }

    @Test("SearchDestinationFeature가 팝업 선택 intent를 받으면 MainTabFeature 내부 상세 path를 연다")
    func searchDestinationPushesPopupDetail() async {
        let popup = Popup.popupMock
        let store = TestStore(
            initialState: SearchDestinationFeature.State(
                userUuid: "user-1",
                nickname: "팝팡"
            )
        ) {
            SearchDestinationFeature()
        }

        await store.send(.search(.delegate(.popupSelected(popup)))) {
            $0.path.append(
                .popupDetail(
                    .init(
                        userUuid: "user-1",
                        popup: popup,
                        isAdmin: false,
                        hidesSystemTabBar: true
                    )
                )
            )
        }
    }

    @Test("프로필 이름 변경을 HomeFeature에 전달하고 설정 화면을 닫는다")
    func updatesHomeNicknameAndDismissesProfileSetting() async {
        let session = makeSession()
        var initialState = MainTabFeature.State(session: session)
        initialState.core.path.append(.profileSetting(.init(user: initialState.core.user)))
        guard let id = initialState.core.path.ids.last else {
            Issue.record("profile setting path should be appended")
            return
        }
        let store = TestStore(initialState: initialState) {
            MainTabFeature()
        }

        await store.send(
            .path(.element(id: id, action: .profileSetting(.delegate(.nicknameUpdated("새 팝팡")))))
        ) {
            $0.core.path.pop(from: id)
            $0.core.user.nickname = "새 팝팡"
            $0.core.home.nickname = "새 팝팡"
            $0.core.profile.nickname = "새 팝팡"
            $0.$session.withLock { $0.user?.nickname = "새 팝팡" }
        }
    }

    @Test("로그아웃 전에 MainTab navigation 상태를 정리한다")
    func clearsNavigationBeforeForwardingLogout() async {
        var initialState = MainTabFeature.State(session: makeSession())
        initialState.core.destination = .popupRequest(
            .init(screen: .popupRequest, userUuid: "user-1")
        )
        initialState.core.path.append(.profileSetting(.init(user: initialState.core.user)))
        guard let id = initialState.core.path.ids.last else {
            Issue.record("profile setting path should be appended")
            return
        }
        let store = TestStore(initialState: initialState) {
            MainTabFeature()
        }

        await store.send(
            .path(.element(id: id, action: .profileSetting(.delegate(.logoutRequested))))
        )

        await store.receive(\.logoutNavigationTeardownRequested) {
            $0.isLoggingOut = true
            $0.core.destination = nil
            $0.core.path = StackState()
        }
        await store.receive(\.logoutNavigationTeardownCompleted)
        await store.receive(\.delegate)
    }
}

private func makeSession() -> Shared<UserSession> {
    Shared(value:
        UserSession(
            user: User(
                userUuid: "user-1",
                uid: "test-uid",
                provider: "test",
                email: nil,
                nickname: "팝팡",
                role: "USER",
                isAlerted: false,
                fcmToken: nil,
                alertKeywordList: nil,
                recommendList: nil
            )
        )
    )
}
