import Foundation

/// 가입 화면의 랜덤 닉네임 추천 응답 (`GET /api/v2/user/nickname/recommendation`)
public struct NicknameRecommendationDTO: Decodable, Sendable {
    public let nickname: String

    public init(nickname: String) {
        self.nickname = nickname
    }
}
