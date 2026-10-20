import Foundation

/// V2 토큰 갱신 응답의 `data`
public struct V2TokenDTO: Decodable, Equatable, Sendable {
    public let accessToken: String
    public let refreshToken: String
}
