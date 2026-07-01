import Core
import Domain

struct SessionState: Equatable, Sendable {
    var user: User?

    var userID: String? {
        user?.userUuid
    }

    var isLoggedIn: Bool {
        user != nil
    }

    var context: SessionContext? {
        userSession.context
    }

    var userSession: UserSession {
        UserSession(user: user)
    }
}
