import Foundation

public struct PushTokenStorage: Sendable {
    private let store: KeyValueStoring
    private let key: String

    public init(
        store: KeyValueStoring,
        key: String = "fcmToken"
    ) {
        self.store = store
        self.key = key
    }

    public func load() -> String? {
        store.object(forKey: key) as? String
    }

    public func save(_ token: String) {
        store.set(token, forKey: key)
    }

    public func remove() {
        store.removeObject(forKey: key)
    }
}
