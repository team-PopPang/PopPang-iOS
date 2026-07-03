import Domain

public struct UserSession: Equatable, Sendable {
    public var user: User?

    public init(user: User? = nil) {
        self.user = user
    }

    public var userID: String? {
        user?.userUuid
    }

    public var isLoggedIn: Bool {
        user != nil
    }

}
