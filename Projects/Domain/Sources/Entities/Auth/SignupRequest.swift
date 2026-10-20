/// 회원가입 입력값
public struct SignupRequest: Equatable, Sendable {
    public let nickname: String
    public let isAlerted: Bool
    public let fcmToken: String?
    public let alertKeywordList: [String]
    public let recommendList: [Int]

    public init(
        nickname: String,
        isAlerted: Bool,
        fcmToken: String?,
        alertKeywordList: [String],
        recommendList: [Int]
    ) {
        self.nickname = nickname
        self.isAlerted = isAlerted
        self.fcmToken = fcmToken
        self.alertKeywordList = alertKeywordList
        self.recommendList = recommendList
    }
}
