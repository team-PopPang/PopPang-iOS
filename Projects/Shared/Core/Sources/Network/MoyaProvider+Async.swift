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
    ///
    /// `data`가 항상 null인 API(`ApiResponse[null]`)는 돌려받을 값이 없으므로 `asyncRequestVoid(_:)`로 요청한다.
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
    /// 다시 보낸 요청도 실패하면 받은 오류를 그대로 던진다.
    /// 갱신이 401이 아닌 이유로 실패하면 원래 요청의 만료 오류를 던진다.
    /// 5002가 아닌 401은 같은 토큰으로 다시 성공할 수 없으므로 토큰을 지우고 `AuthSessionError.loginRequired`를 던진다.
    /// 다만 보낸 뒤에 다른 요청이 토큰을 갱신했으면 지우지 않고, 새 토큰으로 한 번만 다시 보낸다.
    /// 403에는 갱신하지 않는다.
    func asyncRequest(_ target: Target) async throws -> Response {
        guard let authentication = plugins.lazy.compactMap({ $0 as? AuthenticationPlugin }).first,
              AuthenticationPlugin.authorization(of: target) == .access
        else {
            return try await sendRequest(target)
        }

        do {
            return try await sendAuthenticatedRequest(target, authentication: authentication)
        } catch AuthSessionError.loginRequired {
            authentication.onLoginRequired()
            throw AuthSessionError.loginRequired
        }
    }

    func asyncRequestVoid(_ target: Target) async throws {
        _ = try await asyncRequest(target)
    }
}

private extension MoyaProvider {
    func sendAuthenticatedRequest(
        _ target: Target,
        authentication: AuthenticationPlugin
    ) async throws -> Response {
        switch try await sendAccessRequest(target, authentication: authentication) {
        case let .success(response):
            return response

        case let .rejectedWithStaleToken(_, error):
            return try await retryAccessRequest(target, authentication: authentication, originalError: error)

        case let .expired(sentAccessToken, expiredError):
            do {
                _ = try await authentication.refresher.refreshAccessToken(expired: sentAccessToken)
            } catch let error as AuthSessionError {
                throw error
            } catch {
                throw expiredError
            }
            return try await retryAccessRequest(target, authentication: authentication, originalError: expiredError)
        }
    }
}

private enum AccessRequestResult {
    case success(Response)
    /// 401 5002를 받았다. `sentAccessToken`은 그 요청에 실제로 담았던 토큰이다.
    case expired(sentAccessToken: String?, error: NetworkError)
    /// 5002가 아닌 401을 받았는데, 보낸 뒤에 갱신이나 로그인으로 지금은 다른 토큰이 저장돼 있다.
    case rejectedWithStaleToken(sentAccessToken: String?, error: NetworkError)
}

private extension MoyaProvider {
    /// 갱신했거나 새 토큰이 생긴 뒤 원래 요청을 한 번만 다시 보낸다. 다시 보낸 요청이 또 실패하면 그 오류를 던진다.
    func retryAccessRequest(
        _ target: Target,
        authentication: AuthenticationPlugin,
        originalError: NetworkError
    ) async throws -> Response {
        switch try await sendAccessRequest(target, authentication: authentication) {
        case let .success(response):
            return response
        case let .expired(_, error), let .rejectedWithStaleToken(_, error):
            throw error
        }
    }

    func sendAccessRequest(
        _ target: Target,
        authentication: AuthenticationPlugin
    ) async throws -> AccessRequestResult {
        let response = try await sendRawRequest(target)
        guard let error = NetworkError(response: response) else {
            return .success(response)
        }

        let sentAccessToken = response.request?.bearerToken
        if error.isExpiredToken {
            return .expired(sentAccessToken: sentAccessToken, error: error)
        }

        guard error.statusCode == 401 else { throw error }

        let storage = authentication.storage
        guard let sentAccessToken else {
            // 토큰 없이 보냈다. 토큰 쌍이 없으면 로그아웃 상태이고,
            // 보낸 뒤에 로그인으로 쌍이 생겼으면 새 토큰으로 다시 보낸다.
            if storage.removeIncompleteTokens() {
                throw AuthSessionError.loginRequired
            }
            return .rejectedWithStaleToken(sentAccessToken: nil, error: error)
        }

        if storage.removeTokens(ifAccessTokenIs: sentAccessToken) {
            throw AuthSessionError.loginRequired
        }

        // 보낸 뒤에 다른 요청이 토큰을 갱신했다. 새 토큰이 있으면 그 토큰으로 다시 보낸다.
        guard storage.loadTokens() != nil else { throw error }
        return .rejectedWithStaleToken(sentAccessToken: sentAccessToken, error: error)
    }

    func sendRequest(_ target: Target) async throws -> Response {
        let response = try await sendRawRequest(target)
        if let error = NetworkError(response: response) {
            throw error
        }
        return response
    }

    /// 상태 코드와 관계없이 서버 응답을 돌려준다. 응답을 받지 못하면 Moya 오류를 던진다.
    func sendRawRequest(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            request(target) { result in
                continuation.resume(with: result)
            }
        }
    }
}

private extension NetworkError {
    /// 2xx가 아닌 응답이면 오류를 만든다.
    init?(response: Response) {
        guard (200..<300).contains(response.statusCode) == false else { return nil }

        let message = String(data: response.data, encoding: .utf8) ?? "Unknown error"
        self = .invalidStatusCode(response.statusCode, message: message)
    }
}

private extension URLRequest {
    var bearerToken: String? {
        guard let value = value(forHTTPHeaderField: "Authorization"),
              value.hasPrefix("Bearer ")
        else {
            return nil
        }
        return String(value.dropFirst("Bearer ".count))
    }
}
