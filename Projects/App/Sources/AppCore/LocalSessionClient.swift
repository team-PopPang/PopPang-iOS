import ComposableArchitecture
import Core
import Domain

struct LocalSessionClient: Sendable {
    var load: @Sendable () async -> UserSession
    var saveUser: @Sendable (User?) async -> Void
    var clear: @Sendable () async -> Void
    /// 앱을 쓰는 중에 인증 토큰을 쓸 수 없게 돼 다시 로그인해야 할 때마다 값을 보낸다.
    var loginRequiredEvents: @Sendable () -> AsyncStream<Void>
}

extension LocalSessionClient {
    static func live(
        sessionStorage: LocalSessionStorage,
        authUsecase: AuthUsecaseProtocol,
        sessionEvents: AuthSessionEvents
    ) -> Self {
        let authUsecaseBox = AuthUsecaseBox(authUsecase)

        return Self(
            load: {
                do {
                    guard let user = try await authUsecaseBox.usecase.restoreSession() else {
                        sessionStorage.clearSession()
                        return UserSession()
                    }
                    // 아직 V1인 API가 쓰는 사용자 UUID를 저장해 둔다.
                    sessionStorage.saveUserID(user.userUuid)
                    return UserSession(user: user)
                } catch {
                    // 서버 오류나 네트워크 문제라 토큰은 지우지 않고 로그인 화면을 보여 준다. 다음 실행 때 다시 확인한다.
                    Logger.w("세션 복구 실패: \(error.localizedDescription)")
                    return UserSession()
                }
            },
            saveUser: { user in
                sessionStorage.saveUserID(user?.userUuid)
            },
            clear: {
                // 서버 로그아웃을 기다리는 동안 다시 로그인할 수 있으므로 로컬 세션을 먼저 지운다.
                sessionStorage.clearSession()
                await authUsecaseBox.usecase.logout()
            },
            loginRequiredEvents: {
                sessionEvents.loginRequired()
            }
        )
    }
}

private final class AuthUsecaseBox: @unchecked Sendable {
    let usecase: AuthUsecaseProtocol

    init(_ usecase: AuthUsecaseProtocol) {
        self.usecase = usecase
    }
}

extension LocalSessionClient: DependencyKey {
    static let liveValue = LocalSessionClient(
        load: { UserSession() },
        saveUser: { _ in },
        clear: {},
        loginRequiredEvents: { AsyncStream { $0.finish() } }
    )
}

extension DependencyValues {
    var localSessionClient: LocalSessionClient {
        get { self[LocalSessionClient.self] }
        set { self[LocalSessionClient.self] = newValue }
    }
}
