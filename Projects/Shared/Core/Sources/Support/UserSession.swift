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

    public var context: SessionContext? {
        guard let user else { return nil }
        return SessionContext(
            userUuid: user.userUuid,
            nickname: user.nickname ?? "닉네임",
            isAlerted: user.isAlerted,
            isAdmin: user.role.uppercased() == "ADMIN"
        )
    }
}

public struct SessionContext: Equatable, Hashable, Sendable {
    public var userUuid: String
    public var nickname: String
    public var isAlerted: Bool
    public var isAdmin: Bool

    public init(
        userUuid: String,
        nickname: String,
        isAlerted: Bool,
        isAdmin: Bool
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.isAlerted = isAlerted
        self.isAdmin = isAdmin
    }
}
