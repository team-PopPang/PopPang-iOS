import ComposableArchitecture
import Core
import Domain
import Foundation
import MainTabFeature
import Testing
@testable import PopPangApp

@MainActor
struct AppFeatureTests {
    @Test("로그아웃은 메인 플로우가 사라진 뒤 세션을 비운다")
    func logoutClearsSessionAfterMainFlowDisappears() async {
        let user = makeUser()
        var initialState = AppFeature.State(session: UserSession(user: user))
        initialState.destination = .main
        initialState.mainTabCore = .init(session: initialState.$session)

        let store = TestStore(initialState: initialState) {
            AppFeature(
                sessionStorage: LocalSessionStorage(
                    store: UserDefaultsStore(
                        userDefaults: UserDefaults(suiteName: "PopPangAppTests")!
                    )
                ),
                launchStateResolver: AppLaunchStateResolver()
            )
        } withDependencies: {
            $0.localSessionClient.clear = {}
        }

        await store.send(.mainTab(.delegate(.logout))) {
            $0.destination = .onboarding
            $0.isLoggingOut = true
        }

        #expect(store.state.session.user?.userUuid == user.userUuid)
        #expect(store.state.mainTab != nil)

        await store.send(.mainTab(.delegate(.logout)))

        await store.send(.mainFlowDidDisappear) { state in
            state.mainTabCore = nil
            state.$session.withLock { session in
                session = UserSession()
            }
            state.isLoggingOut = false
        }

        #expect(store.state.session.user == nil)
        await store.finish()
    }
}

private func makeUser() -> User {
    User(
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
}
