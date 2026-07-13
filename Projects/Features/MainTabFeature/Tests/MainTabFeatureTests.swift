import ComposableArchitecture
import Core
import Domain
import PopPangRNFeature
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

        await store.send(.home(.delegate(.searchRequested)))

        guard case let .search(searchState)? = store.state.core.destination else {
            Issue.record("search destination should be presented")
            return
        }

        #expect(searchState.search.userUuid == "user-1")
        #expect(searchState.search.nickname == "팝팡")
    }

    @Test("HomeFeature의 팝업 제보 요청을 MainTabFeature가 RN 팝업 제보 presentation으로 연다")
    func presentsPopupRequestFromHomeDelegate() async {
        let store = TestStore(initialState: MainTabFeature.State(session: makeSession())) {
            MainTabFeature()
        }
        store.exhaustivity = .off

        await store.send(.home(.delegate(.popupRequestRequested)))

        guard case let .popupRequest(popupRequestState)? = store.state.core.destination else {
            Issue.record("popup request destination should be presented")
            return
        }

        #expect(popupRequestState.screen == .popupRequest)
        #expect(popupRequestState.userUuid == "user-1")
    }

    @Test("HomeFeature의 관리자 팝업 제보 목록 요청을 MainTabFeature가 RN push path로 연다")
    func pushesPopupRequestManagementFromHomeDelegate() async {
        let store = TestStore(initialState: MainTabFeature.State(session: makeAdminSession())) {
            MainTabFeature()
        }
        store.exhaustivity = .off

        await store.send(.home(.delegate(.popupRequestManagementRequested)))

        guard case let .popupRequestManagement(managementState)? = store.state.core.path.last else {
            Issue.record("popup request management path should be pushed")
            return
        }

        #expect(managementState.screen == .popupRequestManagement)
        #expect(managementState.userUuid == "admin-1")
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

        await store.send(.destination(.presented(.search(.delegate(.dismiss))))) {
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

private func makeAdminSession() -> Shared<UserSession> {
    Shared(value:
        UserSession(
            user: User(
                userUuid: "admin-1",
                uid: "admin-uid",
                provider: "test",
                email: nil,
                nickname: "관리자",
                role: "ADMIN",
                isAlerted: false,
                fcmToken: nil,
                alertKeywordList: nil,
                recommendList: nil
            )
        )
    )
}
