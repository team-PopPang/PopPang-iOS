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
    /// 다시 보낸 요청도 실패하면 받은 오류를 그대로 던진다.
    /// 갱신이 401이 아닌 이유로 실패하면 원래 요청의 만료 오류를 던진다.
    /// 5002가 아닌 401은 같은 토큰으로 다시 성공할 수 없으므로 토큰을 지우고 `AuthSessionError.loginRequired`를 던진다.
    /// 403에는 갱신하지 않는다.
    func asyncRequest(_ target: Target) async throws -> Response {
        guard let authentication = plugins.lazy.compactMap({ $0 as? AuthenticationPlugin }).first,
              AuthenticationPlugin.authorization(of: target) == .access
        else {
            return try await sendRequest(target)
        }

        switch try await sendAccessRequest(target, authentication: authentication) {
        case let .success(response):
            return response

        case let .expired(sentAccessToken, expiredError):
            do {
                _ = try await authentication.refresher.refreshAccessToken(expired: sentAccessToken)
            } catch let error as AuthSessionError {
                throw error
            } catch {
                throw expiredError
            }
            switch try await sendAccessRequest(target, authentication: authentication) {
            case let .success(response):
                return response
            case let .expired(_, error):
                throw error
            }
        }
    }

    func asyncRequestVoid(_ target: Target) async throws {
        _ = try await asyncRequest(target)
    }
}

private enum AccessRequestResult {
    case success(Response)
    /// 401 5002를 받았다. `sentAccessToken`은 그 요청에 실제로 담았던 토큰이다.
    case expired(sentAccessToken: String?, error: NetworkError)
}

private extension MoyaProvider {
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

        // 보낸 뒤에 다른 요청이 토큰을 갱신했거나 Keychain을 읽지 못하면, 이 실패로 토큰을 지우지 않는다.
        guard (try? authentication.storage.removeTokens(ifAccessTokenIs: sentAccessToken)) == true else {
            throw error
        }
        throw AuthSessionError.loginRequired
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
