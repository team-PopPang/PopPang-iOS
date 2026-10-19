import Foundation
@testable import Core

/// UserDefaults 대신 메모리에 값을 두는 테스트용 저장소.
final class InMemoryStore: Storing, @unchecked Sendable {
    struct SaveError: Error {}

    private let lock = NSLock()
    private var values: [String: Any] = [:]
    private var _failingKeys: Set<String> = []

    /// 이 키에 저장하면 `SaveError`를 던진다.
    var failingKeys: Set<String> {
        get { lock.withLock { _failingKeys } }
        set { lock.withLock { _failingKeys = newValue } }
    }

    func value<T>(forKey key: String) -> T? {
        lock.withLock { values[key] as? T }
    }

    func set<T>(_ value: T, forKey key: String) throws {
        try lock.withLock {
            guard _failingKeys.contains(key) == false else { throw SaveError() }
            values[key] = value
        }
    }

    func removeValue(forKey key: String) {
        lock.withLock { _ = values.removeValue(forKey: key) }
    }
}
