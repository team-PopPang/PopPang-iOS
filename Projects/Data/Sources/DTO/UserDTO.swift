import Domain
import Foundation

public struct UserDTO: Codable, Sendable {
    public let userUuid: String
    public let uid: String
    public let provider: String
    public let email: String?
    public let nickname: String?
    public let role: String
    public let isAlerted: Bool
    public let fcmToken: String?
    public let alertKeywordList: [String]?
    public let recommendList: [Int]?

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

public extension UserDTO {
    func toModel() -> Domain.User {
        Domain.User(
            userUuid: userUuid,
            uid: uid,
            provider: provider,
            email: email,
            nickname: nickname,
            role: role,
            isAlerted: isAlerted,
            fcmToken: fcmToken,
            alertKeywordList: alertKeywordList,
            recommendList: recommendList
        )
    }

    static let adminUser = UserDTO(
        userUuid: "1234",
        uid: "0000",
        provider: "kakao",
        email: "index@example.com",
        nickname: "김동현",
        role: "user",
        isAlerted: false,
        fcmToken: "",
        alertKeywordList: ["팝업스토어", "카페"],
        recommendList: [1, 2]
    )
}
