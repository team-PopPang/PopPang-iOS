import Foundation
import Moya

public extension MoyaProvider {
    func asyncRequest<T: Decodable>(
        _ target: Target,
        decodeTo type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        let response = try await asyncRequest(target)
        return try decoder.decode(T.self, from: response.data)
    }

    /// 성공 응답이 `APIResponse`로 감싸진 V2 API를 요청하고 `data`만 돌려준다.
    func asyncRequest<T: Decodable>(
        _ target: Target,
        decodeDataTo type: T.Type,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        try await asyncRequest(target, decodeTo: APIResponse<T>.self, decoder: decoder).data
    }

    /// 요청을 보낸다.
    ///
    /// Access Token이 필요한 요청이 401 5002(만료)를 받으면 토큰을 한 번 갱신하고 원래 요청을 한 번만 다시 보낸다.
    /// 5002가 아닌 401은 같은 토큰으로 다시 성공할 수 없으므로 토큰을 지우고 `AuthSessionError.loginRequired`를 던진다.
    /// 403에는 갱신하지 않는다.
    func asyncRequest(_ target: Target) async throws -> Response {
        guard let authentication = plugins.lazy.compactMap({ $0 as? AuthenticationPlugin }).first,
              AuthenticationPlugin.authorization(of: target) == .access
        else {
            return try await sendRequest(target)
        }

        let usedAccessToken = authentication.token(for: target)
        do {
            return try await sendAccessRequest(target, authentication: authentication)
        } catch let error as NetworkError where error.isExpiredToken {
            _ = try await authentication.refresher.refreshAccessToken(expired: usedAccessToken)
            return try await sendAccessRequest(target, authentication: authentication)
        }
    }

    func asyncRequestVoid(_ target: Target) async throws {
        _ = try await asyncRequest(target)
    }
}

private extension MoyaProvider {
    func sendAccessRequest(
        _ target: Target,
        authentication: AuthenticationPlugin
    ) async throws -> Response {
        do {
            return try await sendRequest(target)
        } catch let error as NetworkError where error.statusCode == 401 && !error.isExpiredToken {
            authentication.storage.removeTokens()
            throw AuthSessionError.loginRequired
        }
    }

    func sendRequest(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            request(target) { result in
                switch result {
                case let .success(response):
                    guard (200..<300).contains(response.statusCode) else {
                        let message = String(data: response.data, encoding: .utf8) ?? "Unknown error"
                        continuation.resume(
                            throwing: NetworkError.invalidStatusCode(
                                response.statusCode,
                                message: message
                            )
                        )
                        return
                    }

                    continuation.resume(returning: response)

                case let .failure(error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
