import Foundation

/// V2 로그인·회원가입·토큰 갱신이 주는 토큰 쌍.
public struct AuthTokens: Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String

    public init(accessToken: String, refreshToken: String) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
