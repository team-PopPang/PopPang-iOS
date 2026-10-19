import Foundation

public enum UserDefaultsStoreError: Error, Equatable, Sendable {
    /// UserDefaults에 저장할 수 없는 타입이다(property list 타입만 저장할 수 있다).
    case unsupportedType(String)
}

public final class UserDefaultsStore: Storing, @unchecked Sendable {
    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func value<T>(forKey key: String) -> T? {
        userDefaults.object(forKey: key) as? T
    }

    /// 값이 `nil`이면 키를 지운다. property list 타입이 아니면 저장하지 않고 오류를 던진다.
    public func set<T>(_ value: T, forKey key: String) throws {
        guard let value = Self.unwrapped(value) else {
            userDefaults.removeObject(forKey: key)
            return
        }

        guard PropertyListSerialization.propertyList(value, isValidFor: .binary) else {
            throw UserDefaultsStoreError.unsupportedType(String(describing: type(of: value)))
        }
        userDefaults.set(value, forKey: key)
    }

    public func removeValue(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
}

private extension UserDefaultsStore {
    /// `Optional`로 감싼 값을 벗긴다. `nil`이면 `nil`을 돌려준다.
    static func unwrapped(_ value: Any) -> Any? {
        let mirror = Mirror(reflecting: value)
        guard mirror.displayStyle == .optional else { return value }
        guard let wrapped = mirror.children.first?.value else { return nil }
        return unwrapped(wrapped)
    }
}
