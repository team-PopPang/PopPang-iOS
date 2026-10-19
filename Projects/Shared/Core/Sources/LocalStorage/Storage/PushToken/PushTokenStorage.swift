import Foundation

public struct PushTokenStorage: Sendable {
    private let store: Storing
    private let key: String

    public init(
        store: Storing,
        key: String = "fcmToken"
    ) {
        self.store = store
        self.key = key
    }

    public func load() -> String? {
        store.value(forKey: key)
    }

    public func save(_ token: String) {
        try? store.set(token, forKey: key)
    }

    public func remove() {
        store.removeValue(forKey: key)
    }
}
