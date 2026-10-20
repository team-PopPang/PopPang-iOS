import Foundation

/// V2 소셜 로그인·회원가입 응답의 `data`
///
/// `signupStatus`가 `COMPLETED`면 사용자와 토큰 쌍이, `PENDING`이면 가입 전용 토큰만 온다.
public struct V2LoginDataDTO: Decodable, Equatable, Sendable {
    public let signupStatus: String
    public let user: V2AuthUserDTO?
    public let accessToken: String?
    public let refreshToken: String?
    public let signupToken: String?
}
