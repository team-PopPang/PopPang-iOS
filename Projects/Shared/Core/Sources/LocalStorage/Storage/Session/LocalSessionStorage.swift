import Foundation

public struct LocalSessionStorage: Sendable {
    enum Key {
        static let userID = "uuid"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }

    private let store: Storing

    public init(store: Storing) {
        self.store = store
    }

    public func loadSnapshot() -> LocalSessionSnapshot {
        let userID: String? = store.value(forKey: Key.userID)
        let hasCompletedOnboarding: Bool = store.value(forKey: Key.hasCompletedOnboarding) ?? false

        return LocalSessionSnapshot(
            userID: userID,
            hasCompletedOnboarding: hasCompletedOnboarding
        )
    }

    public func saveUserID(_ userID: String?) {
        guard let userID, userID.isEmpty == false else {
            store.removeValue(forKey: Key.userID)
            return
        }

        try? store.set(userID, forKey: Key.userID)
    }

    public func setOnboardingCompleted(_ isCompleted: Bool) {
        try? store.set(isCompleted, forKey: Key.hasCompletedOnboarding)
    }

    public func clearSession() {
        store.removeValue(forKey: Key.userID)
    }
}
