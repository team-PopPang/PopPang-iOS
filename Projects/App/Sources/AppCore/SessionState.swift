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
        guard let user else { return nil }
        return SessionContext(
            userUuid: user.userUuid,
            nickname: user.nickname ?? "닉네임",
            isAlerted: user.isAlerted,
            isAdmin: user.role.uppercased() == "ADMIN"
        )
    }

}

struct SessionContext: Equatable, Hashable, Sendable {
    var userUuid: String
    var nickname: String
    var isAlerted: Bool
    var isAdmin: Bool
}
