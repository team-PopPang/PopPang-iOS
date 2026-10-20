/// 사용자 권한
public enum Role: String, Equatable, Sendable {
    case admin = "ADMIN"
    case member = "MEMBER"
}

public struct User: Equatable, Sendable {
    public let userUuid: String
    public let provider: Provider?
    public let email: String?
    public var nickname: String?
    public let role: Role?
    public var isAlerted: Bool

    public init(
        userUuid: String,
        provider: Provider?,
        email: String?,
        nickname: String?,
        role: Role?,
        isAlerted: Bool
    ) {
        self.userUuid = userUuid
        self.provider = provider
        self.email = email
        self.nickname = nickname
        self.role = role
        self.isAlerted = isAlerted
    }

    public var isAdmin: Bool {
        role == .admin
    }
}

public extension User {
    static let adminUser = User(
        userUuid: "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13",
        provider: .kakao,
        email: "john@example.com",
        nickname: "UI테스터",
        role: .admin,
        isAlerted: false
    )
}
