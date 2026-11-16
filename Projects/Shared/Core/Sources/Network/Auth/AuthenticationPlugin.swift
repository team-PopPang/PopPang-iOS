import Foundation
import Moya

/// V2 요청에 `Authorization` 헤더를 붙이고, Access Token 만료를 처리할 refresher를 들고 있는 Moya plugin.
///
/// 만료 응답을 받은 요청을 다시 보내는 일은 `MoyaProvider.asyncRequest(_:)`가 이 plugin을 찾아서 한다.
public struct AuthenticationPlugin: PluginType {
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

    /// 네트워크 계층 밖(React Native 화면 등)에서 V2 API를 부를 때 쓸 Access Token을 돌려준다.
    ///
    /// - Parameter forceRefresh: 그 토큰으로 보낸 요청이 401을 받았으면 `true`. 저장된 토큰을 갱신해 돌려준다.
    ///   다른 요청이 이미 갱신했으면 다시 갱신하지 않고 새 토큰을 돌려준다.
    /// - Returns: 로그아웃 상태이거나 갱신에 실패하면 `nil`.
    ///   Refresh Token도 쓸 수 없으면(`AuthSessionError.loginRequired`) 앱의 다른 요청처럼 다시 로그인해야 한다고 알린다.
    public func accessToken(forceRefresh: Bool) async -> String? {
        guard let accessToken = storage.loadTokens()?.accessToken else { return nil }
        guard forceRefresh else { return accessToken }

        do {
            return try await refresher.refreshAccessToken(expired: accessToken)
        } catch AuthSessionError.loginRequired {
            sessionEvents?.notifyLoginRequired()
            return nil
        } catch {
            return nil
        }
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
