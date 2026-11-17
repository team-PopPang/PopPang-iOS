import Foundation

/// 네트워크 계층 밖(React Native 화면 등)이 Access Token을 요청했을 때의 답.
public enum HostAccessTokenResult: Equatable, Sendable {
    case accessToken(String)
    /// 다시 로그인해야 한다. 앱의 다른 요청처럼 로그인 화면으로 보내라고 이미 알렸다.
    case loginRequired
    /// 네트워크·서버 문제로 지금은 토큰을 주지 못했다. 저장된 토큰은 그대로다.
    case temporaryFailure

    public var accessToken: String? {
        if case let .accessToken(token) = self { return token }
        return nil
    }

    public var isTemporaryFailure: Bool { self == .temporaryFailure }
}

public extension AuthenticationPlugin {
    /// 네트워크 계층 밖에서 V2 API를 부를 때 쓸 Access Token을 돌려준다. 401 처리는 `MoyaProvider.asyncRequest`와 같은 규칙을 따른다.
    ///
    /// - Parameters:
    ///   - rejectedAccessToken: `nil`이면 지금 쓸 토큰을 요청한다. 값이 있으면 그 토큰으로 보낸 요청이 401을 받았다.
    ///   - expired: 401의 서버 코드가 5002(Access Token 만료)면 `true`. 그 토큰을 만료된 토큰으로 넘겨 갱신한다.
    ///     다른 요청이 이미 갱신했으면 다시 갱신하지 않고 새 토큰을 돌려준다.
    ///     `false`면 그 토큰이 아직 저장돼 있을 때 토큰을 지우고 로그아웃한다. 그사이 다른 토큰으로 바뀌었으면 그 토큰을 돌려준다.
    func hostAccessToken(rejected rejectedAccessToken: String?, expired: Bool) async -> HostAccessTokenResult {
        do {
            return .accessToken(try await resolveHostAccessToken(rejected: rejectedAccessToken, expired: expired))
        } catch AuthSessionError.loginRequired {
            sessionEvents?.notifyLoginRequired()
            return .loginRequired
        } catch {
            return .temporaryFailure
        }
    }
}

private extension AuthenticationPlugin {
    func resolveHostAccessToken(rejected rejectedAccessToken: String?, expired: Bool) async throws -> String {
        guard let rejectedAccessToken else {
            if let accessToken = storage.loadTokens()?.accessToken {
                return accessToken
            }
            // 토큰 쌍이 없으면 로그아웃 상태다. 그사이 로그인으로 쌍이 생겼으면 그 토큰을 쓴다.
            if storage.removeIncompleteTokens() {
                throw AuthSessionError.loginRequired
            }
            return try storedAccessToken()
        }

        if expired {
            return try await refresher.refreshAccessToken(expired: rejectedAccessToken)
        }

        // 만료가 아닌 401: 그 토큰이 아직 저장돼 있으면 쓸 수 없는 토큰이므로 지우고 로그아웃한다.
        if storage.removeTokens(ifAccessTokenIs: rejectedAccessToken) {
            throw AuthSessionError.loginRequired
        }
        return try storedAccessToken()
    }

    func storedAccessToken() throws -> String {
        guard let accessToken = storage.loadTokens()?.accessToken else {
            throw AuthSessionError.loginRequired
        }
        return accessToken
    }
}
