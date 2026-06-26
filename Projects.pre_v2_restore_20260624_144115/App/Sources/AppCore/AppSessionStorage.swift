import Core
import Foundation

struct AppSessionStorage: Sendable {
    enum Key {
        static let userID = "uuid"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let fcmToken = "fcmToken"
        static let deepLinkPopupID = "deeplinkPopupId"
    }

    private let store: KeyValueStoring

    init(store: KeyValueStoring) {
        self.store = store
    }

    func loadSnapshot() -> AppSessionSnapshot {
        let userID = store.object(forKey: Key.userID) as? String
        let hasCompletedOnboarding = store.object(forKey: Key.hasCompletedOnboarding) as? Bool ?? false
        let fcmToken = store.object(forKey: Key.fcmToken) as? String
        let deepLinkPopupID = store.object(forKey: Key.deepLinkPopupID) as? String

        return AppSessionSnapshot(
            userID: userID,
            hasCompletedOnboarding: hasCompletedOnboarding,
            fcmToken: fcmToken,
            deepLinkPopupID: deepLinkPopupID
        )
    }

    func saveUserID(_ userID: String?) {
        guard let userID, userID.isEmpty == false else {
            store.removeObject(forKey: Key.userID)
            return
        }

        store.set(userID, forKey: Key.userID)
    }

    func setOnboardingCompleted(_ isCompleted: Bool) {
        store.set(isCompleted, forKey: Key.hasCompletedOnboarding)
    }

    func saveFCMToken(_ token: String?) {
        guard let token, token.isEmpty == false else {
            store.removeObject(forKey: Key.fcmToken)
            return
        }

        store.set(token, forKey: Key.fcmToken)
    }

    func saveDeepLinkPopupID(_ popupID: String?) {
        guard let popupID, popupID.isEmpty == false else {
            store.removeObject(forKey: Key.deepLinkPopupID)
            return
        }

        store.set(popupID, forKey: Key.deepLinkPopupID)
    }

    func clearDeepLinkPopupID() {
        store.removeObject(forKey: Key.deepLinkPopupID)
    }

    func clearSession() {
        store.removeObject(forKey: Key.userID)
    }
}
