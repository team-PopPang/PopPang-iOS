import Foundation

public final class UserDefaultsStore: KeyValueStoring, @unchecked Sendable {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func object(forKey key: String) -> Any? {
        userDefaults.object(forKey: key)
    }

    public func set(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }

    public func removeObject(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}
