import Foundation

/// V2 인증 토큰을 Keychain에 저장한다.
///
/// 토큰은 UserDefaults, 로그, 분석 이벤트에 남기지 않는다.
/// 토큰 갱신·로그아웃이 여러 스레드에서 겹쳐도 확인과 저장·삭제가 섞이지 않도록 모든 동작을 한 lock으로 묶는다.
public struct AuthTokenStorage: Sendable {
    enum Key {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let signupToken = "signupToken"
    }

    /// 같은 Keychain을 쓰는 모든 인스턴스가 함께 쓰는 lock
    private static let lock = NSRecursiveLock()

    private let store: KeychainStoring

    public init(store: KeychainStoring = KeychainStore()) {
        self.store = store
    }

    /// Access·Refresh Token이 모두 있을 때만 토큰 쌍을 돌려준다. Keychain을 읽지 못하면 오류를 던진다.
    public func loadTokens() throws -> AuthTokens? {
        try withLock {
            guard let accessToken = try store.value(forKey: Key.accessToken),
                  let refreshToken = try store.value(forKey: Key.refreshToken)
            else {
                return nil
            }
            return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
        }
    }

    /// 새 토큰 쌍을 함께 저장한다. 하나라도 저장하지 못하면 둘 다 지운다.
    ///
    /// Refresh Token을 먼저 쓴다. 지우는 것까지 실패해 한쪽만 남더라도 새 Refresh Token과 옛 Access Token이 남아,
    /// 옛 Access Token이 만료되면 새 Refresh Token으로 다시 갱신할 수 있다.
    public func saveTokens(_ tokens: AuthTokens) throws {
        try withLock {
            do {
                try store.set(tokens.refreshToken, forKey: Key.refreshToken)
                try store.set(tokens.accessToken, forKey: Key.accessToken)
            } catch {
                try? removeTokens()
                throw error
            }
        }
    }

    /// 저장된 Refresh Token이 `expectedRefreshToken`일 때만 새 토큰 쌍으로 바꾼다.
    ///
    /// - Returns: 바꿨으면 `true`. 그사이 로그아웃·재로그인으로 토큰이 바뀌었으면 저장하지 않고 `false`
    public func replaceTokens(_ tokens: AuthTokens, ifRefreshTokenIs expectedRefreshToken: String) throws -> Bool {
        try withLock {
            guard try loadTokens()?.refreshToken == expectedRefreshToken else { return false }
            try saveTokens(tokens)
            return true
        }
    }

    /// 저장된 Access Token이 `accessToken`일 때만 토큰 쌍을 지운다.
    ///
    /// - Returns: 지웠으면 `true`. 그사이 토큰이 바뀌었으면 지우지 않고 `false`
    public func removeTokens(ifAccessTokenIs accessToken: String) throws -> Bool {
        try withLock {
            guard try store.value(forKey: Key.accessToken) == accessToken else { return false }
            try removeTokens()
            return true
        }
    }

    /// 저장된 Refresh Token이 `refreshToken`일 때만 토큰 쌍을 지운다.
    ///
    /// - Returns: 지웠으면 `true`. 그사이 토큰이 바뀌었으면 지우지 않고 `false`
    public func removeTokens(ifRefreshTokenIs refreshToken: String) throws -> Bool {
        try withLock {
            guard try loadTokens()?.refreshToken == refreshToken else { return false }
            try removeTokens()
            return true
        }
    }

    /// Access·Refresh Token 가운데 하나라도 있으면 `true`. 쌍이 다 갖춰지지 않아도 남은 토큰이 있는지 본다.
    public func hasAnyToken() throws -> Bool {
        try withLock {
            try store.value(forKey: Key.accessToken) != nil
                || store.value(forKey: Key.refreshToken) != nil
        }
    }

    public func loadSignupToken() throws -> String? {
        try withLock { try store.value(forKey: Key.signupToken) }
    }

    public func saveSignupToken(_ token: String) throws {
        try withLock { try store.set(token, forKey: Key.signupToken) }
    }

    public func removeSignupToken() throws {
        try withLock { try store.removeValue(forKey: Key.signupToken) }
    }

    /// Access·Refresh Token을 지운다. 하나를 지우지 못해도 나머지는 지우고, 처음 실패한 오류를 던진다.
    public func removeTokens() throws {
        try withLock { try removeValues(forKeys: [Key.accessToken, Key.refreshToken]) }
    }

    /// Signup Token까지 모든 인증 토큰을 지운다. 하나를 지우지 못해도 나머지는 지우고, 처음 실패한 오류를 던진다.
    public func clear() throws {
        try withLock { try removeValues(forKeys: [Key.accessToken, Key.refreshToken, Key.signupToken]) }
    }
}

private extension AuthTokenStorage {
    func removeValues(forKeys keys: [String]) throws {
        var firstError: Error?
        for key in keys {
            do {
                try store.removeValue(forKey: key)
            } catch {
                firstError = firstError ?? error
            }
        }
        if let firstError {
            throw firstError
        }
    }

    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return try body()
    }
}
