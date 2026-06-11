import Foundation

public struct DeepLinkStorage: Sendable {
    private let store: KeyValueStoring
    private let key: String

    public init(
        store: KeyValueStoring,
        key: String = "deeplinkPopupId"
    ) {
        self.store = store
        self.key = key
    }

    public func loadPopupID() -> String? {
        store.object(forKey: key) as? String
    }

    public func savePopupID(_ popupID: String) {
        store.set(popupID, forKey: key)
    }

    public func removePopupID() {
        store.removeObject(forKey: key)
    }
}
