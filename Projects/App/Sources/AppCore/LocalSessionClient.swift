import ComposableArchitecture
import Core
import Domain

struct LocalSessionClient: Sendable {
    var load: @Sendable () async -> UserSession
    var saveUser: @Sendable (User?) async -> Void
    var clear: @Sendable () async -> Void
}

extension LocalSessionClient {
    static func live(
        sessionStorage: LocalSessionStorage,
        userUsecase: UserUsecaseProtocol
    ) -> Self {
        Self(
            load: {
                let snapshot = sessionStorage.loadSnapshot()
                guard let userID = snapshot.userID, userID.isEmpty == false else {
                    return UserSession()
                }

                do {
                    let user = try await userUsecase.autoLogin(userUuid: userID)
                    return UserSession(user: user)
                } catch {
                    return UserSession()
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

extension LocalSessionClient: DependencyKey {
    static let liveValue = LocalSessionClient(
        load: { UserSession() },
        saveUser: { _ in },
        clear: {}
    )
}

extension DependencyValues {
    var localSessionClient: LocalSessionClient {
        get { self[LocalSessionClient.self] }
        set { self[LocalSessionClient.self] = newValue }
    }
}
