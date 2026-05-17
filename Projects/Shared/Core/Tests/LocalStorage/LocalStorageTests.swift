import Foundation
import Testing
@testable import Core

struct LocalStorageTests {
    @Test
    func storesAndRemovesValueInUserDefaultsStore() {
        let suiteName = "CoreTests.UserDefaultsStore"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(userDefaults: userDefaults)
        store.set("hello", forKey: "greeting")

        #expect(store.object(forKey: "greeting") as? String == "hello")

        store.removeObject(forKey: "greeting")

        #expect(store.object(forKey: "greeting") == nil)
    }

    @Test
    func recentSearchStorageDeduplicatesAndKeepsLatestFiveKeywords() {
        let suiteName = "CoreTests.RecentSearchStorage"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(userDefaults: userDefaults)
        let recentSearchStorage = RecentSearchStorage(store: store)

        recentSearchStorage.add("성수")
        recentSearchStorage.add("홍대")
        recentSearchStorage.add("연남")
        recentSearchStorage.add("여의도")
        recentSearchStorage.add("잠실")
        recentSearchStorage.add("성수")
        recentSearchStorage.add("부산")

        #expect(
            recentSearchStorage.load() == ["부산", "성수", "잠실", "여의도", "연남"]
        )

        recentSearchStorage.remove("잠실")

        #expect(recentSearchStorage.load() == ["부산", "성수", "여의도", "연남"])
    }

    @Test
    func storesAndRemovesPushTokenAndDeepLinkValues() {
        let suiteName = "CoreTests.StorageValues"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(userDefaults: userDefaults)
        let pushTokenStorage = PushTokenStorage(store: store)
        let deepLinkStorage = DeepLinkStorage(store: store)

        pushTokenStorage.save("fcm-token")
        deepLinkStorage.savePopupID("123")

        #expect(pushTokenStorage.load() == "fcm-token")
        #expect(deepLinkStorage.loadPopupID() == "123")

        pushTokenStorage.remove()
        deepLinkStorage.removePopupID()

        #expect(pushTokenStorage.load() == nil)
        #expect(deepLinkStorage.loadPopupID() == nil)
    }
}
