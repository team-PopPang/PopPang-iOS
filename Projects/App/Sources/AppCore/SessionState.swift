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

    static func == (lhs: Self, rhs: Self) -> Bool {
        SessionUserSnapshot(lhs.user) == SessionUserSnapshot(rhs.user)
    }
}

struct SessionContext: Equatable, Hashable, Sendable {
    var userUuid: String
    var nickname: String
    var isAlerted: Bool
    var isAdmin: Bool
}

private struct SessionUserSnapshot: Equatable {
    let userUuid: String?
    let uid: String?
    let provider: String?
    let email: String?
    let nickname: String?
    let role: String?
    let isAlerted: Bool?
    let fcmToken: String?
    let alertKeywordList: [String]?
    let recommendList: [Int]?

    init(_ user: User?) {
        userUuid = user?.userUuid
        uid = user?.uid
        provider = user?.provider
        email = user?.email
        nickname = user?.nickname
        role = user?.role
        isAlerted = user?.isAlerted
        fcmToken = user?.fcmToken
        alertKeywordList = user?.alertKeywordList
        recommendList = user?.recommendList
    }
}
