import Foundation
@testable import Core

/// Keychain 대신 메모리에 값을 두는 테스트용 저장소.
final class InMemoryKeychainStore: KeychainStoring, @unchecked Sendable {
    struct SaveError: Error {}
    struct ReadError: Error {}
    struct DeleteError: Error {}

    private let lock = NSLock()
    private var values: [String: String] = [:]
    private var _failingKeys: Set<String> = []
    private var _unreadableKeys: Set<String> = []
    private var _undeletableKeys: Set<String> = []

    /// 이 키에 저장하면 `SaveError`를 던진다.
    var failingKeys: Set<String> {
        get { lock.withLock { _failingKeys } }
        set { lock.withLock { _failingKeys = newValue } }
    }

    /// 이 키를 읽으면 `ReadError`를 던진다. 기기가 잠겨 Keychain을 읽지 못하는 상황을 만든다.
    var unreadableKeys: Set<String> {
        get { lock.withLock { _unreadableKeys } }
        set { lock.withLock { _unreadableKeys = newValue } }
    }

    func value(forKey key: String) throws -> String? {
        try lock.withLock {
            guard _unreadableKeys.contains(key) == false else { throw ReadError() }
            return values[key]
        }
    }

    func set(_ value: String, forKey key: String) throws {
        try lock.withLock {
            guard _failingKeys.contains(key) == false else { throw SaveError() }
            values[key] = value
        }
    }

    /// 이 키를 지우면 `DeleteError`를 던진다.
    var undeletableKeys: Set<String> {
        get { lock.withLock { _undeletableKeys } }
        set { lock.withLock { _undeletableKeys = newValue } }
    }

    func removeValue(forKey key: String) throws {
        try lock.withLock {
            guard _undeletableKeys.contains(key) == false else { throw DeleteError() }
            _ = values.removeValue(forKey: key)
        }
    }
}
