import Foundation
import Testing
@testable import Core

struct LocalStorageTests {
    @Test("UserDefaultsStore가 값을 저장하고 삭제한다")
    func storesAndRemovesValueInUserDefaultsStore() throws {
        let suiteName = "CoreTests.UserDefaultsStore"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(userDefaults: userDefaults)
        try store.set("hello", forKey: "greeting")

        #expect(store.value(forKey: "greeting") == "hello")

        store.removeValue(forKey: "greeting")

        #expect((store.value(forKey: "greeting") as String?) == nil)
    }

    @Test("UserDefaultsStore는 nil을 넣으면 키를 지우고, 저장할 수 없는 타입은 오류를 던진다")
    func userDefaultsStoreRemovesNilAndRejectsUnsupportedType() throws {
        let suiteName = "CoreTests.UserDefaultsStoreValues"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)
        let store = UserDefaultsStore(userDefaults: userDefaults)

        try store.set(Optional("hello"), forKey: "greeting")
        #expect(store.value(forKey: "greeting") == "hello")

        try store.set(String?.none, forKey: "greeting")
        #expect((store.value(forKey: "greeting") as String?) == nil)

        struct Unsupported {}
        #expect(throws: UserDefaultsStoreError.self) {
            try store.set(Unsupported(), forKey: "unsupported")
        }
        #expect(userDefaults.object(forKey: "unsupported") == nil)
    }

    @Test("최근 검색어 저장소가 중복을 제거하고 최신 다섯 개만 유지한다")
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

    @Test("푸시 토큰과 딥링크 값을 저장하고 삭제한다")
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

    @Test("앱 세션 저장소는 userID와 온보딩 여부만 저장한다")
    func appSessionStorageStoresOnlyRestoreHints() {
        let suiteName = "CoreTests.LocalSessionStorage"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        userDefaults.removePersistentDomain(forName: suiteName)

        let store = UserDefaultsStore(userDefaults: userDefaults)
        let appSessionStorage = LocalSessionStorage(store: store)

        appSessionStorage.saveUserID("user-1")
        appSessionStorage.setOnboardingCompleted(true)

        let snapshot = appSessionStorage.loadSnapshot()

        #expect(snapshot.userID == "user-1")
        #expect(snapshot.hasCompletedOnboarding)

        appSessionStorage.clearSession()

        #expect(appSessionStorage.loadSnapshot().userID == nil)
        #expect(appSessionStorage.loadSnapshot().hasCompletedOnboarding)
    }
}
