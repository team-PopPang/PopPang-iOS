import Foundation

/// V2 인증 토큰을 Keychain에 저장한다.
///
/// 토큰은 UserDefaults, 로그, 분석 이벤트에 남기지 않는다.
public struct AuthTokenStorage: Sendable {
    enum Key {
        static let accessToken = "accessToken"
        static let refreshToken = "refreshToken"
        static let signupToken = "signupToken"
    }

    private let store: KeychainStoring

    public init(store: KeychainStoring = KeychainStore()) {
        self.store = store
    }

    /// Access·Refresh Token이 모두 있을 때만 토큰 쌍을 돌려준다.
    public func loadTokens() -> AuthTokens? {
        guard let accessToken = store.value(forKey: Key.accessToken),
              let refreshToken = store.value(forKey: Key.refreshToken)
        else {
            return nil
        }
        return AuthTokens(accessToken: accessToken, refreshToken: refreshToken)
    }

    /// 새 토큰 쌍을 함께 저장한다. 하나라도 저장하지 못하면 둘 다 지운다.
    public func saveTokens(_ tokens: AuthTokens) throws {
        do {
            try store.set(tokens.accessToken, forKey: Key.accessToken)
            try store.set(tokens.refreshToken, forKey: Key.refreshToken)
        } catch {
            removeTokens()
            throw error
        }
    }

    public func loadSignupToken() -> String? {
        store.value(forKey: Key.signupToken)
    }

    public func saveSignupToken(_ token: String) throws {
        try store.set(token, forKey: Key.signupToken)
    }

    public func removeSignupToken() {
        store.removeValue(forKey: Key.signupToken)
    }

    /// Access·Refresh Token을 지운다.
    public func removeTokens() {
        store.removeValue(forKey: Key.accessToken)
        store.removeValue(forKey: Key.refreshToken)
    }

    /// Signup Token까지 모든 인증 토큰을 지운다.
    public func clear() {
        removeTokens()
        removeSignupToken()
    }
}
