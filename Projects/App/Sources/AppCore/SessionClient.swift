import Core
import Domain

struct SessionClient: Sendable {
    var load: @Sendable () async -> SessionState
    var saveUser: @Sendable (User?) async -> Void
    var clear: @Sendable () async -> Void
}

extension SessionClient {
    static func live(
        sessionStorage: AppSessionStorage,
        userUsecase: UserUsecaseProtocol
    ) -> Self {
        Self(
            load: {
                let snapshot = sessionStorage.loadSnapshot()
                guard let userID = snapshot.userID, userID.isEmpty == false else {
                    return SessionState()
                }

                do {
                    let user = try await userUsecase.autoLogin(userUuid: userID)
                    return SessionState(user: user)
                } catch {
                    return SessionState()
                }
            },
            saveUser: { user in
                sessionStorage.saveUserID(user?.userUuid)
            },
            clear: {
                sessionStorage.clearSession()
            }
        )
    }
}
