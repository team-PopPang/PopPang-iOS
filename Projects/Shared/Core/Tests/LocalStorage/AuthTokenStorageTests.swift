import Foundation
import Testing
@testable import Core

struct AuthTokenStorageTests {
    @Test("토큰 쌍과 Signup Token을 저장하고 지운다")
    func storesAndClearsTokens() throws {
        let storage = AuthTokenStorage(store: InMemoryStore())
        let tokens = AuthTokens(accessToken: "access", refreshToken: "refresh")

        try storage.saveTokens(tokens)
        try storage.saveSignupToken("signup")

        #expect(storage.loadTokens() == tokens)
        #expect(storage.loadSignupToken() == "signup")

        storage.removeTokens()

        #expect(storage.loadTokens() == nil)
        #expect(storage.loadSignupToken() == "signup")

        try storage.saveTokens(tokens)
        storage.clear()

        #expect(storage.loadTokens() == nil)
        #expect(storage.loadSignupToken() == nil)
    }

    @Test("토큰 쌍 가운데 하나라도 저장하지 못하면 둘 다 지운다")
    func removesBothTokensWhenSavingFails() throws {
        let store = InMemoryStore()
        let storage = AuthTokenStorage(store: store)
        try storage.saveTokens(AuthTokens(accessToken: "old-access", refreshToken: "old-refresh"))
        store.failingKeys = [AuthTokenStorage.Key.refreshToken]

        #expect(throws: InMemoryStore.SaveError.self) {
            try storage.saveTokens(AuthTokens(accessToken: "new-access", refreshToken: "new-refresh"))
        }
        #expect(storage.loadTokens() == nil)
    }

    @Test("저장된 토큰이 기대한 값일 때만 바꾸거나 지운다")
    func replacesAndRemovesOnlyWhenTokensMatch() throws {
        let storage = AuthTokenStorage(store: InMemoryStore())
        let oldTokens = AuthTokens(accessToken: "old-access", refreshToken: "old-refresh")
        let newTokens = AuthTokens(accessToken: "new-access", refreshToken: "new-refresh")
        try storage.saveTokens(oldTokens)

        #expect(try storage.replaceTokens(newTokens, ifRefreshTokenIs: "other-refresh") == false)
        #expect(storage.loadTokens() == oldTokens)
        #expect(try storage.replaceTokens(newTokens, ifRefreshTokenIs: "old-refresh"))
        #expect(storage.loadTokens() == newTokens)

        #expect(storage.removeTokens(ifAccessTokenIs: "old-access") == false)
        #expect(storage.removeTokens(ifRefreshTokenIs: "old-refresh") == false)
        #expect(storage.loadTokens() == newTokens)
        #expect(storage.removeTokens(ifAccessTokenIs: "new-access"))
        #expect(storage.loadTokens() == nil)
    }

    @Test("Refresh Token만 남아 있어도 남은 토큰이 있다고 알려 준다")
    func reportsLoneRefreshToken() throws {
        let store = InMemoryStore()
        let storage = AuthTokenStorage(store: store)
        try store.set("refresh", forKey: AuthTokenStorage.Key.refreshToken)

        #expect(storage.loadTokens() == nil)
        #expect(storage.hasAnyToken())

        store.removeValue(forKey: AuthTokenStorage.Key.refreshToken)
        #expect(storage.hasAnyToken() == false)
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
