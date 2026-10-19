import Foundation

public enum AuthSessionError: Error, Equatable, Sendable {
    /// 인증 토큰을 쓸 수 없어 지웠다. 소셜 로그인부터 다시 해야 한다.
    case loginRequired
}

/// 만료된 Access Token을 Refresh Token으로 갱신한다.
///
/// 여러 요청이 동시에 만료돼도 갱신 요청은 하나만 보내고, 나머지 요청은 그 결과를 기다린다.
public actor AccessTokenRefresher {
    /// 서버에 토큰 갱신을 요청하고 새 토큰 쌍을 돌려준다. 실패는 `NetworkError`로 던진다.
    public typealias Refresh = @Sendable (_ refreshToken: String) async throws -> AuthTokens

    private let storage: AuthTokenStorage
    private let refresh: Refresh
    private var inFlightRefresh: Task<String, Error>?

    public init(
        storage: AuthTokenStorage,
        refresh: @escaping Refresh
    ) {
        self.storage = storage
        self.refresh = refresh
    }

    /// 새 Access Token을 돌려준다.
    ///
    /// - Parameter expiredAccessToken: 401 5002를 받은 요청에 담았던 토큰.
    ///   저장된 토큰이 이 값과 다르면 다른 요청이 이미 갱신한 것이므로 다시 갱신하지 않는다.
    /// - Throws: 갱신 API가 401을 주거나 Refresh Token이 없으면 토큰을 지우고 `AuthSessionError.loginRequired`를 던진다.
    ///   그 밖의 실패(400, 403, 429, 503, 500, 네트워크 오류)는 토큰을 그대로 두고 받은 오류를 던진다.
    public func refreshAccessToken(expired expiredAccessToken: String?) async throws -> String {
        if let currentAccessToken = storage.loadTokens()?.accessToken,
           currentAccessToken != expiredAccessToken {
            return currentAccessToken
        }

        if let inFlightRefresh {
            return try await inFlightRefresh.value
        }

        let task = Task { [storage, refresh] in
            try await Self.performRefresh(storage: storage, refresh: refresh)
        }
        inFlightRefresh = task
        defer { inFlightRefresh = nil }
        return try await task.value
    }
}

private extension AccessTokenRefresher {
    static func performRefresh(
        storage: AuthTokenStorage,
        refresh: Refresh
    ) async throws -> String {
        guard let refreshToken = storage.loadTokens()?.refreshToken else {
            storage.removeTokens()
            throw AuthSessionError.loginRequired
        }

        let tokens: AuthTokens
        do {
            tokens = try await refresh(refreshToken)
        } catch let error as NetworkError where error.statusCode == 401 {
            guard storage.loadTokens()?.refreshToken == refreshToken else {
                return try replacedAccessToken(in: storage)
            }
            storage.removeTokens()
            throw AuthSessionError.loginRequired
        }

        // 갱신하는 동안 로그아웃·재로그인으로 토큰이 바뀌었으면 늦게 온 응답으로 덮어쓰지 않는다.
        guard storage.loadTokens()?.refreshToken == refreshToken else {
            return try replacedAccessToken(in: storage)
        }

        do {
            try storage.saveTokens(tokens)
        } catch {
            // 서버는 이미 이전 Refresh Token을 폐기했으므로 저장하지 못한 토큰으로는 세션을 이어 갈 수 없다.
            throw AuthSessionError.loginRequired
        }
        return tokens.accessToken
    }

    /// 갱신하는 동안 바뀐 토큰을 따른다. 재로그인으로 새 토큰이 있으면 그 Access Token을, 로그아웃으로 없으면 로그인을 요구한다.
    static func replacedAccessToken(in storage: AuthTokenStorage) throws -> String {
        guard let accessToken = storage.loadTokens()?.accessToken else {
            throw AuthSessionError.loginRequired
        }
        return accessToken
    }
}
