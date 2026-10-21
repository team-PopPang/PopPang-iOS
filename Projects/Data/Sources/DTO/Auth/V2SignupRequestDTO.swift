import Domain
import Foundation

/// V2 회원가입 요청 본문. 가입 대상은 가입 전용 토큰으로 정하므로 사용자 식별값을 넣지 않는다.
public struct V2SignupRequestDTO: Encodable, Equatable, Sendable {
    public let nickname: String
    public let isAlerted: Bool
    public let fcmToken: String?
    public let alertKeywordList: [String]
    public let recommendList: [Int]
    /// 가입한 OS. 서버가 가입 정보와 가입 알림 메일에 표시한다(2026-10-21 서버 계약 추가). iOS 앱은 항상 `IOS`다.
    public let signupOs = "IOS"

    init(_ request: SignupRequest) {
        nickname = request.nickname
        isAlerted = request.isAlerted
        fcmToken = request.fcmToken
        alertKeywordList = request.alertKeywordList
        recommendList = request.recommendList
    }
}
