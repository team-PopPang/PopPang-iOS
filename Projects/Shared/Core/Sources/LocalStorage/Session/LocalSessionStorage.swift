import Foundation

public struct LocalSessionStorage: Sendable {
    enum Key {
        static let userID = "uuid"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let store: KeyValueStoring

    public init(store: KeyValueStoring) {
        self.store = store
    }

    public func loadSnapshot() -> LocalSessionSnapshot {
        let userID = store.object(forKey: Key.userID) as? String
        let hasCompletedOnboarding = store.object(forKey: Key.hasCompletedOnboarding) as? Bool ?? false

        return LocalSessionSnapshot(
            userID: userID,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
    }

    public func saveUserID(_ userID: String?) {
        guard let userID, userID.isEmpty == false else {
            store.removeObject(forKey: Key.userID)
            return
        }

        store.set(userID, forKey: Key.userID)
    }

    public func setOnboardingCompleted(_ isCompleted: Bool) {
        store.set(isCompleted, forKey: Key.hasCompletedOnboarding)
    }

    public func clearSession() {
        store.removeObject(forKey: Key.userID)
    }
}
