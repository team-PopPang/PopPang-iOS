public struct User: Equatable, Sendable {
    public let userUuid: String
    public let uid: String
    public let provider: String
    public let email: String?
    public var nickname: String?
    public let role: String
    public var isAlerted: Bool
    public var fcmToken: String?
    public var alertKeywordList: [String]?
    public var recommendList: [Int]?

    public init(
        userUuid: String,
        uid: String,
        provider: String,
        email: String?,
        nickname: String?,
        role: String,
        isAlerted: Bool,
        fcmToken: String?,
        alertKeywordList: [String]?,
        recommendList: [Int]?
    ) {
        self.userUuid = userUuid
        self.uid = uid
        self.provider = provider
        self.email = email
        self.nickname = nickname
        self.role = role
        self.isAlerted = isAlerted
        self.fcmToken = fcmToken
        self.alertKeywordList = alertKeywordList
        self.recommendList = recommendList
    }
}

public extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.userUuid == rhs.userUuid
            && lhs.uid == rhs.uid
            && lhs.provider == rhs.provider
            && lhs.email == rhs.email
            && lhs.nickname == rhs.nickname
            && lhs.role == rhs.role
            && lhs.isAlerted == rhs.isAlerted
            && lhs.fcmToken == rhs.fcmToken
            && lhs.alertKeywordList == rhs.alertKeywordList
            && lhs.recommendList == rhs.recommendList
    }
}

public extension User {
    static let adminUser = User(
        userUuid: "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13",
        uid: "67890",
        provider: "kakao",
        email: "john@example.com",
        nickname: "UI테스터",
        role: "admin",
        isAlerted: false,
        fcmToken: "",
        alertKeywordList: ["팝업스토어", "카페"],
        recommendList: [1, 2]
    )
}
