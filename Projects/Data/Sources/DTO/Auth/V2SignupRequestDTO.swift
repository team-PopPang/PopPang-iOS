import Domain
import Foundation

/// V2 회원가입 요청 본문. 가입 대상은 가입 전용 토큰으로 정하므로 사용자 식별값을 넣지 않는다.
public struct V2SignupRequestDTO: Encodable, Equatable, Sendable {
    public let nickname: String
    public let isAlerted: Bool
    public let fcmToken: String?
    public let alertKeywordList: [String]
    public let recommendList: [Int]

    init(_ request: SignupRequest) {
        nickname = request.nickname
        isAlerted = request.isAlerted
        fcmToken = request.fcmToken
        alertKeywordList = request.alertKeywordList
        recommendList = request.recommendList
    }
}
