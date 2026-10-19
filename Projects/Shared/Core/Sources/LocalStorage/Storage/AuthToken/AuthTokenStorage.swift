import Foundation

/// V2 인증 토큰을 저장한다.
///
/// 기본 저장 수단은 UserDefaults(`UserDefaultsStore`)다. 서버 명세는 Keychain 저장을 요구하지만,
/// 앱을 지우면 토큰도 함께 지워지도록 UserDefaults를 쓰기로 정했다([V2 API 마이그레이션] 문서의 결정 사항).
/// 토큰은 로그와 분석 이벤트에 남기지 않는다.
/// 토큰 갱신·로그아웃이 여러 스레드에서 겹쳐도 확인과 저장·삭제가 섞이지 않도록 모든 동작을 한 lock으로 묶는다.
public struct AuthTokenStorage: Sendable {
    enum Key {
        static let accessToken = "auth.accessToken"
        static let refreshToken = "auth.refreshToken"
        static let signupToken = "auth.signupToken"
    }

    /// 같은 저장 수단을 쓰는 모든 인스턴스가 함께 쓰는 lock
    private static let lock = NSRecursiveLock()

    private let store: Storing

    public init(store: Storing = UserDefaultsStore()) {
        self.store = store
    }

    /// Access·Refresh Token이 모두 있을 때만 토큰 쌍을 돌려준다.
    public func loadTokens() -> AuthTokens? {
        withLock {
            guard let accessToken: String = store.value(forKey: Key.accessToken),
                  let refreshToken: String = store.value(forKey: Key.refreshToken)
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
                removeTokens()
                throw error
            }
        }
    }

    /// 저장된 Refresh Token이 `expectedRefreshToken`일 때만 새 토큰 쌍으로 바꾼다.
    ///
    /// - Returns: 바꿨으면 `true`. 그사이 로그아웃·재로그인으로 토큰이 바뀌었으면 저장하지 않고 `false`
    public func replaceTokens(_ tokens: AuthTokens, ifRefreshTokenIs expectedRefreshToken: String) throws -> Bool {
        try withLock {
            guard loadTokens()?.refreshToken == expectedRefreshToken else { return false }
            try saveTokens(tokens)
            return true
        }
    }

    /// 저장된 Access Token이 `accessToken`일 때만 토큰 쌍을 지운다.
    ///
    /// - Returns: 지웠으면 `true`. 그사이 토큰이 바뀌었으면 지우지 않고 `false`
    public func removeTokens(ifAccessTokenIs accessToken: String) -> Bool {
        withLock {
            guard (store.value(forKey: Key.accessToken) as String?) == accessToken else { return false }
            removeTokens()
            return true
        }
    }

    /// 저장된 Refresh Token이 `refreshToken`일 때만 토큰 쌍을 지운다.
    ///
    /// - Returns: 지웠으면 `true`. 그사이 토큰이 바뀌었으면 지우지 않고 `false`
    public func removeTokens(ifRefreshTokenIs refreshToken: String) -> Bool {
        withLock {
            guard (store.value(forKey: Key.refreshToken) as String?) == refreshToken else { return false }
            removeTokens()
            return true
        }
    }

    /// Access·Refresh Token 가운데 하나라도 있으면 `true`. 쌍이 다 갖춰지지 않아도 남은 토큰이 있는지 본다.
    public func hasAnyToken() -> Bool {
        withLock {
            (store.value(forKey: Key.accessToken) as String?) != nil
                || (store.value(forKey: Key.refreshToken) as String?) != nil
        }
    }

    public func loadSignupToken() -> String? {
        withLock { store.value(forKey: Key.signupToken) }
    }

    public func saveSignupToken(_ token: String) throws {
        try withLock { try store.set(token, forKey: Key.signupToken) }
    }

    public func removeSignupToken() {
        withLock { store.removeValue(forKey: Key.signupToken) }
    }

    /// Access·Refresh Token을 지운다.
    public func removeTokens() {
        withLock {
            store.removeValue(forKey: Key.accessToken)
            store.removeValue(forKey: Key.refreshToken)
        }
    }

    /// Signup Token까지 모든 인증 토큰을 지운다.
    public func clear() {
        withLock {
            store.removeValue(forKey: Key.accessToken)
            store.removeValue(forKey: Key.refreshToken)
            store.removeValue(forKey: Key.signupToken)
        }
    }
}

private extension AuthTokenStorage {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        Self.lock.lock()
        defer { Self.lock.unlock() }
        return try body()
    }
}
