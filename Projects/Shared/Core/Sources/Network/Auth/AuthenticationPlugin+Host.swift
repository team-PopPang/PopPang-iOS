import Foundation

/// 네트워크 계층 밖(React Native 화면 등)이 Access Token을 요청했을 때의 답.
public enum HostAccessTokenResult: Equatable, Sendable {
    case accessToken(String)
    /// 다시 로그인해야 한다. 로그인 화면으로 보내는 알림(`AuthSessionEvents`)은 이 요청이 보냈거나, 토큰을 지운 다른 요청이 보냈다.
    ///
    /// 여러 요청이 동시에 실패하면 앱 요청(`MoyaProvider.asyncRequest`)과 마찬가지로 알림이 여러 번 갈 수 있다.
    /// `AppFeature`는 메인 화면에 있고 로그아웃 중이 아닐 때만 처리하므로 화면 전환은 한 번만 일어난다.
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
            if let accessToken = storage.loadTokens()?.accessToken {
                return .accessToken(accessToken)
            }
            // RN 화면은 Access Token이 필요한 V2 API만 부른다. 토큰 없이 보내면 401이 오므로
            // 보내지 않고 "토큰 없이 보낸 요청이 401을 받은" 경우와 똑같이 처리한다.
            return resolveUnauthorized(sentAccessToken: nil)
        }

        guard expired else {
            return resolveUnauthorized(sentAccessToken: rejectedAccessToken)
        }

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
    func resolveUnauthorized(sentAccessToken: String?) -> HostAccessTokenResult {
        switch handleUnauthorized(sentAccessToken: sentAccessToken) {
        case .loginRequired:
            sessionEvents?.notifyLoginRequired()
            return .loginRequired

        case .alreadyLoggedOut:
            return .loginRequired

        case .retryWithStoredToken:
            // 판단과 읽기 사이에 다시 로그아웃됐으면, 토큰을 지운 쪽이 이미 알렸다.
            guard let accessToken = storage.loadTokens()?.accessToken else { return .loginRequired }
            return .accessToken(accessToken)
        }
    }
}
