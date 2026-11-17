import Foundation

/// 네트워크 계층 밖(React Native 화면 등)이 Access Token을 요청했을 때의 답.
public enum HostAccessTokenResult: Equatable, Sendable {
    case accessToken(String)
    /// 다시 로그인해야 한다. 이 요청이 토큰을 지웠거나 갱신이 거절됐으면 로그인 화면으로 보내라고 알렸다(`AuthSessionEvents`).
    /// 다른 요청이 이미 토큰을 지운 뒤라면 그 요청이 알렸으므로 다시 알리지 않는다.
    case loginRequired
    /// 네트워크·서버 문제로 지금은 토큰을 주지 못했다. 저장된 토큰은 그대로다.
    case temporaryFailure
}

public extension AuthenticationPlugin {
    /// 네트워크 계층 밖에서 V2 API를 부를 때 쓸 Access Token을 돌려준다.
    ///
    /// 401 처리는 `MoyaProvider.asyncRequest(_:)`와 같은 판단(`handleUnauthorized(sentAccessToken:)`, `AccessTokenRefresher`)을 쓴다.
    /// 갱신 횟수도 같다. 호출하는 쪽(RN)은 요청마다 한 번만 다시 받아 재시도하고,
    /// 갱신은 넘긴 토큰이 아직 저장된 토큰일 때만 일어난다.
    ///
    /// - Parameters:
    ///   - rejectedAccessToken: `nil`이면 지금 쓸 토큰을 요청한다. 값이 있으면 그 토큰으로 보낸 요청이 401을 받았다.
    ///   - expired: 401의 서버 코드가 5002(Access Token 만료)면 `true`. 그 토큰을 만료된 토큰으로 넘겨 갱신한다.
    ///     다른 요청이 이미 갱신했으면 다시 갱신하지 않고 새 토큰을 돌려준다.
    func hostAccessToken(rejected rejectedAccessToken: String?, expired: Bool) async -> HostAccessTokenResult {
        guard let rejectedAccessToken else {
            // 아직 요청을 보내지 않았으므로 서버가 세션을 거절했다는 근거가 없다. 토큰을 지우거나 로그인 화면으로 보내지 않는다.
            // 토큰 쌍이 없으면 이미 로그아웃됐거나(그 경로가 알렸다) 앱 요청이 서버 응답으로 판단한다.
            guard let accessToken = storage.loadTokens()?.accessToken else { return .loginRequired }
            return .accessToken(accessToken)
        }

        guard expired else {
            return resolveUnauthorized(sentAccessToken: rejectedAccessToken)
        }

        // 보낸 뒤에 다른 요청이 토큰을 지웠다. 그 요청이 이미 로그인 화면으로 보냈으므로 갱신하지 않고 다시 알리지 않는다.
        guard storage.loadTokens() != nil else { return .loginRequired }

        do {
            return .accessToken(try await refresher.refreshAccessToken(expired: rejectedAccessToken))
        } catch AuthSessionError.loginRequired {
            sessionEvents?.notifyLoginRequired()
            return .loginRequired
        } catch {
            return .temporaryFailure
        }
    }
}

private extension AuthenticationPlugin {
    func resolveUnauthorized(sentAccessToken: String) -> HostAccessTokenResult {
        switch handleUnauthorized(sentAccessToken: sentAccessToken) {
        case .loginRequired:
            sessionEvents?.notifyLoginRequired()
            return .loginRequired

        case .alreadyLoggedOut:
            return .loginRequired

        case let .retryWithStoredToken(accessToken):
            return .accessToken(accessToken)
        }
    }
}
