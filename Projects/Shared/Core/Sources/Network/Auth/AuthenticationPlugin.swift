import Foundation
import Moya

/// V2 요청에 `Authorization` 헤더를 붙이고, Access Token 만료를 처리할 refresher를 들고 있는 Moya plugin.
///
/// 만료 응답을 받은 요청을 다시 보내는 일은 `MoyaProvider.asyncRequest(_:)`가 이 plugin을 찾아서 한다.
public struct AuthenticationPlugin: PluginType {
    public let storage: AuthTokenStorage
    public let refresher: AccessTokenRefresher

    public init(
        storage: AuthTokenStorage,
        refresher: AccessTokenRefresher
    ) {
        self.storage = storage
        self.refresher = refresher
    }

    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let token = token(for: target) else { return request }

        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    /// 요청에 담을 토큰. 인증이 필요 없는 요청이거나 토큰이 없거나 저장소를 읽지 못하면 `nil`이다.
    func token(for target: TargetType) -> String? {
        switch Self.authorization(of: target) {
        case .none:
            return nil
        case .access:
            return (try? storage.loadTokens())?.accessToken
        case .signup:
            return (try? storage.loadSignupToken()) ?? nil
        }
    }

    static func authorization(of target: TargetType) -> APIAuthorization {
        let target = (target as? MultiTarget)?.target ?? target
        return (target as? BaseAPI)?.resolvedAuthorization ?? .none
    }
}
