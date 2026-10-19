import Foundation

public struct DeepLinkStorage: Sendable {
    private let store: Storing
    private let key: String

    public init(
        store: Storing,
        key: String = "deeplinkPopupId"
    ) {
        self.store = store
        self.key = key
    }

    public func loadPopupID() -> String? {
        store.value(forKey: key)
    }

    public func savePopupID(_ popupID: String) {
        try? store.set(popupID, forKey: key)
    }

    public func removePopupID() {
        store.removeValue(forKey: key)
    }
}
