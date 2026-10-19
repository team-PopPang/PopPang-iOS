import Foundation
import Testing
@testable import Core

struct AuthTokenStorageTests {
    @Test("토큰 쌍과 Signup Token을 저장하고 지운다")
    func storesAndClearsTokens() throws {
        let storage = AuthTokenStorage(store: InMemorySecureStore())
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
        let store = InMemorySecureStore()
        let storage = AuthTokenStorage(store: store)
        try storage.saveTokens(AuthTokens(accessToken: "old-access", refreshToken: "old-refresh"))
        store.failingKeys = [AuthTokenStorage.Key.refreshToken]

        #expect(throws: InMemorySecureStore.SaveError.self) {
            try storage.saveTokens(AuthTokens(accessToken: "new-access", refreshToken: "new-refresh"))
        }
        #expect(storage.loadTokens() == nil)
    }

    /// 앱 없이 실행하는 CoreTests에는 Keychain entitlement가 없어(-34018) 이 테스트를 건너뛴다.
    @Test(
        "Keychain에 문자열을 저장하고 덮어쓰고 지운다",
        .enabled(if: isKeychainAvailable(), "Keychain entitlement가 없는 테스트 환경")
    )
    func keychainStoreStoresUpdatesAndRemovesValue() throws {
        let store = KeychainStore(service: "com.poppang.core.tests.\(UUID().uuidString)")
        let key = "token"
        defer { store.removeValue(forKey: key) }

        try store.set("first", forKey: key)
        #expect(store.string(forKey: key) == "first")

        try store.set("second", forKey: key)
        #expect(store.string(forKey: key) == "second")

        store.removeValue(forKey: key)
        #expect(store.string(forKey: key) == nil)
    }
}

private func isKeychainAvailable() -> Bool {
    let store = KeychainStore(service: "com.poppang.core.tests.probe")
    defer { store.removeValue(forKey: "probe") }
    return (try? store.set("probe", forKey: "probe")) != nil
}
