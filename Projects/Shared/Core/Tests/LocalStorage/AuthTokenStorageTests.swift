import Foundation
import Testing
@testable import Core

struct AuthTokenStorageTests {
    @Test("토큰 쌍과 Signup Token을 저장하고 지운다")
    func storesAndClearsTokens() throws {
        let storage = AuthTokenStorage(store: InMemoryKeychainStore())
        let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")

        try storage.saveTokens(tokens)
        try storage.saveSignupToken("signup")

        #expect(try storage.loadTokens() == tokens)
        #expect(try storage.loadSignupToken() == "signup")

        try storage.removeTokens()

        #expect(try storage.loadTokens() == nil)
        #expect(try storage.loadSignupToken() == "signup")

        try storage.saveTokens(tokens)
        try storage.clear()

        #expect(try storage.loadTokens() == nil)
        #expect(try storage.loadSignupToken() == nil)
    }

    @Test("토큰 쌍 가운데 하나라도 저장하지 못하면 둘 다 지운다")
    func removesBothTokensWhenSavingFails() throws {
        let store = InMemoryKeychainStore()
        let storage = AuthTokenStorage(store: store)
        try storage.saveTokens(AuthTokens(accessToken: "old-access", refreshToken: "old-refresh"))
        store.failingKeys = [AuthTokenStorage.Key.refreshToken]

        #expect(throws: InMemoryKeychainStore.SaveError.self) {
            try storage.saveTokens(AuthTokens(accessToken: "new-access", refreshToken: "new-refresh"))
        }
        #expect(try storage.loadTokens() == nil)
    }

    @Test("저장된 토큰이 기대한 값일 때만 바꾸거나 지운다")
    func replacesAndRemovesOnlyWhenTokensMatch() throws {
        let storage = AuthTokenStorage(store: InMemoryKeychainStore())
        let oldTokens = AuthTokens(accessToken: "old-access", refreshToken: "old-refresh")
        let newTokens = AuthTokens(accessToken: "new-access", refreshToken: "new-refresh")
        try storage.saveTokens(oldTokens)

        #expect(try storage.replaceTokens(newTokens, ifRefreshTokenIs: "other-refresh") == false)
        #expect(try storage.loadTokens() == oldTokens)
        #expect(try storage.replaceTokens(newTokens, ifRefreshTokenIs: "old-refresh"))
        #expect(try storage.loadTokens() == newTokens)

        #expect(try storage.removeTokens(ifAccessTokenIs: "old-access") == false)
        #expect(try storage.removeTokens(ifRefreshTokenIs: "old-refresh") == false)
        #expect(try storage.loadTokens() == newTokens)
        #expect(try storage.removeTokens(ifAccessTokenIs: "new-access"))
        #expect(try storage.loadTokens() == nil)
    }

    @Test("Keychain을 읽지 못하면 토큰이 없다고 하지 않고 오류를 던진다")
    func throwsWhenKeychainIsUnreadable() throws {
        let store = InMemoryKeychainStore()
        let storage = AuthTokenStorage(store: store)
        try storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))
        store.unreadableKeys = [AuthTokenStorage.Key.accessToken]

        #expect(throws: InMemoryKeychainStore.ReadError.self) {
            _ = try storage.loadTokens()
        }
        #expect(throws: InMemoryKeychainStore.ReadError.self) {
            _ = try storage.removeTokens(ifAccessTokenIs: "access")
        }

        store.unreadableKeys = []
        #expect(try storage.loadTokens() != nil)
    }

    @Test("토큰 하나를 지우지 못해도 나머지는 지우고 실패를 알린다")
    func reportsDeleteFailure() throws {
        let store = InMemoryKeychainStore()
        let storage = AuthTokenStorage(store: store)
        try storage.saveTokens(AuthTokens(accessToken: "access", refreshToken: "refresh"))
        store.undeletableKeys = [AuthTokenStorage.Key.accessToken]

        #expect(throws: InMemoryKeychainStore.DeleteError.self) {
            try storage.removeTokens()
        }
        #expect(try store.value(forKey: AuthTokenStorage.Key.refreshToken) == nil)
        #expect(try store.value(forKey: AuthTokenStorage.Key.accessToken) == "access")
    }

    @Test("Access Token 저장에 실패하고 되돌리기도 실패하면 새 Refresh Token이 남는다")
    func keepsNewRefreshTokenWhenRollbackFails() throws {
        let store = InMemoryKeychainStore()
        let storage = AuthTokenStorage(store: store)
        try storage.saveTokens(AuthTokens(accessToken: "old-access", refreshToken: "old-refresh"))
        store.failingKeys = [AuthTokenStorage.Key.accessToken]
        store.undeletableKeys = [AuthTokenStorage.Key.accessToken, AuthTokenStorage.Key.refreshToken]

        #expect(throws: InMemoryKeychainStore.SaveError.self) {
            try storage.saveTokens(AuthTokens(accessToken: "new-access", refreshToken: "new-refresh"))
        }
        #expect(try storage.loadTokens() == AuthTokens(accessToken: "old-access", refreshToken: "new-refresh"))
    }

    @Test("Refresh Token만 남아 있어도 남은 토큰이 있다고 알려 준다")
    func reportsLoneRefreshToken() throws {
        let store = InMemoryKeychainStore()
        let storage = AuthTokenStorage(store: store)
        try store.set("refresh", forKey: AuthTokenStorage.Key.refreshToken)

        #expect(try storage.loadTokens() == nil)
        #expect(try storage.hasAnyToken())

        try store.removeValue(forKey: AuthTokenStorage.Key.refreshToken)
        #expect(try storage.hasAnyToken() == false)
    }

    /// 앱 없이 실행하는 CoreTests에는 Keychain entitlement가 없어(-34018) 이 테스트를 건너뛴다.
    @Test(
        "Keychain에 문자열을 저장하고 덮어쓰고 지운다",
        .enabled(if: isKeychainAvailable(), "Keychain entitlement가 없는 테스트 환경")
    )
    func keychainStoreStoresUpdatesAndRemovesValue() throws {
        let store = KeychainStore(service: "com.poppang.core.tests.\(UUID().uuidString)")
        let key = "token"
        defer { try? store.removeValue(forKey: key) }

        try store.set("first", forKey: key)
        #expect(try store.value(forKey: key) == "first")

        try store.set("second", forKey: key)
        #expect(try store.value(forKey: key) == "second")

        try store.removeValue(forKey: key)
        #expect(try store.value(forKey: key) == nil)
    }
}

private func isKeychainAvailable() -> Bool {
    let store = KeychainStore(service: "com.poppang.core.tests.probe")
    defer { try? store.removeValue(forKey: "probe") }
    return (try? store.set("probe", forKey: "probe")) != nil
}
