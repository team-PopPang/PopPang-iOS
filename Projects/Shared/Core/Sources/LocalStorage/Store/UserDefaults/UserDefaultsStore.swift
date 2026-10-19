import Foundation

public final class UserDefaultsStore: Storing, @unchecked Sendable {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func value<T>(forKey key: String) -> T? {
        userDefaults.object(forKey: key) as? T
    }

    /// UserDefaults에 저장할 수 있는 값(property list 타입)만 넣는다. 실패하지 않는다.
    public func set<T>(_ value: T, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
