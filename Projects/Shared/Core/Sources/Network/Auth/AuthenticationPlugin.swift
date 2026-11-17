import Foundation
import Moya

/// V2 요청에 `Authorization` 헤더를 붙이고, Access Token 만료를 처리할 refresher를 들고 있는 Moya plugin.
///
/// 만료 응답을 받은 요청을 다시 보내는 일은 `MoyaProvider.asyncRequest(_:)`가 이 plugin을 찾아서 한다.
public struct AuthenticationPlugin: PluginType, Sendable {
    public let storage: AuthTokenStorage
    public let refresher: AccessTokenRefresher
    /// Access Token이 필요한 요청이 `AuthSessionError.loginRequired`로 끝났음을 알릴 곳
    let sessionEvents: AuthSessionEvents?

    public init(
        storage: AuthTokenStorage,
        refresher: AccessTokenRefresher,
        sessionEvents: AuthSessionEvents? = nil
    ) {
        self.storage = storage
        self.refresher = refresher
        self.sessionEvents = sessionEvents
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let token = token(for: target) else { return request }

        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// 요청에 담을 토큰. 인증이 필요 없는 요청이거나 토큰이 없으면 `nil`이다.
    func token(for target: TargetType) -> String? {
        switch Self.authorization(of: target) {
        case .none:
            return nil
        case .access:
            return storage.loadTokens()?.accessToken
        case .signup:
            return storage.loadSignupToken()
        }
    }

    static func authorization(of target: TargetType) -> APIAuthorization {
        let target = (target as? MultiTarget)?.target ?? target
        return (target as? BaseAPI)?.resolvedAuthorization ?? .none
    }
}

/// Access Token으로 보낸 요청이 5002(만료)가 아닌 401을 받은 뒤 할 일.
///
/// 앱 요청(`MoyaProvider.asyncRequest(_:)`)과 React Native 토큰 요청(`hostAccessToken(rejected:expired:)`)이 같은 판단을 쓴다.
enum UnauthorizedAccessTokenOutcome: Equatable {
    /// 보낸 토큰이 아직 저장돼 있어 지웠거나, 토큰 없이 보냈는데 토큰 쌍이 없다. 로그인 화면으로 보내야 한다.
    case loginRequired
    /// 보낸 뒤에 갱신이나 로그인으로 다른 토큰이 저장됐다. 그 토큰으로 한 번 다시 보낸다.
    case retryWithStoredToken
    /// 보낸 뒤에 다른 요청이 토큰을 지웠다. 그 요청이 이미 로그인 화면으로 보냈으므로 다시 알리지 않는다.
    case alreadyLoggedOut
}

extension AuthenticationPlugin {
    /// 5002가 아닌 401을 받은 요청의 토큰을 정리하고 다음에 할 일을 정한다.
    ///
    /// - Parameter sentAccessToken: 그 요청에 실제로 담았던 Access Token. 토큰 없이 보냈으면 `nil`
    func handleUnauthorized(sentAccessToken: String?) -> UnauthorizedAccessTokenOutcome {
        guard let sentAccessToken else {
            // 토큰 쌍이 없으면 로그아웃 상태다. 보낸 뒤에 로그인으로 쌍이 생겼으면 새 토큰으로 다시 보낸다.
            return storage.removeIncompleteTokens() ? .loginRequired : .retryWithStoredToken
        }

        if storage.removeTokens(ifAccessTokenIs: sentAccessToken) {
            return .loginRequired
        }
        return storage.loadTokens() == nil ? .alreadyLoggedOut : .retryWithStoredToken
    }
}
