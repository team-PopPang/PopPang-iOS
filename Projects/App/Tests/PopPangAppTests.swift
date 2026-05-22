import Coordinator
import Core
import Domain
import Foundation
import Testing
@testable import PopPangApp

struct PopPangAppTests {
    @Test
    func launchStateResolverReturnsOnboardingForFreshInstall() {
        let resolver = AppLaunchStateResolver()
        let snapshot = AppSessionSnapshot(
            userID: nil,
            hasCompletedOnboarding: false,
            fcmToken: nil,
            deepLinkPopupID: nil
        )

        #expect(resolver.resolve(snapshot: snapshot) == .onboarding)
    }

    @Test
    func launchStateResolverReturnsAuthAfterOnboardingCompletion() {
        let resolver = AppLaunchStateResolver()
        let snapshot = AppSessionSnapshot(
            userID: nil,
            hasCompletedOnboarding: true,
            fcmToken: nil,
            deepLinkPopupID: nil
        )

        #expect(resolver.resolve(snapshot: snapshot) == .auth)
    }

    @Test
    func launchStateResolverReturnsMainWhenUserSessionExists() {
        let resolver = AppLaunchStateResolver()
        let snapshot = AppSessionSnapshot(
            userID: "user-123",
            hasCompletedOnboarding: false,
            fcmToken: nil,
            deepLinkPopupID: nil
        )

        #expect(resolver.resolve(snapshot: snapshot) == .main)
    }

    @Test
    func sessionStorageLoadsValuesFromStore() {
        let defaults = UserDefaults(suiteName: "PopPangAppTests.sessionStorageLoadsValuesFromStore")!
        defaults.removePersistentDomain(forName: "PopPangAppTests.sessionStorageLoadsValuesFromStore")

        let storage = AppSessionStorage(store: UserDefaultsStore(userDefaults: defaults))
        storage.setOnboardingCompleted(true)
        storage.saveUserID("stored-user")
        storage.saveFCMToken("stored-fcm-token")
        storage.saveDeepLinkPopupID("popup-123")

        let snapshot = storage.loadSnapshot()

        #expect(snapshot.userID == "stored-user")
        #expect(snapshot.hasCompletedOnboarding)
        #expect(snapshot.fcmToken == "stored-fcm-token")
        #expect(snapshot.deepLinkPopupID == "popup-123")
    }

    @Test
    func sessionStorageClearsOptionalSessionValues() {
        let defaults = UserDefaults(suiteName: "PopPangAppTests.sessionStorageClearsOptionalSessionValues")!
        defaults.removePersistentDomain(forName: "PopPangAppTests.sessionStorageClearsOptionalSessionValues")

        let storage = AppSessionStorage(store: UserDefaultsStore(userDefaults: defaults))
        storage.saveUserID("stored-user")
        storage.saveFCMToken("stored-fcm-token")
        storage.saveDeepLinkPopupID("popup-123")

        storage.saveUserID(nil)
        storage.saveFCMToken(nil)
        storage.clearDeepLinkPopupID()

        let snapshot = storage.loadSnapshot()

        #expect(snapshot.userID == nil)
        #expect(snapshot.fcmToken == nil)
        #expect(snapshot.deepLinkPopupID == nil)
    }

    @Test
    @MainActor
    func bootstrapBuildsRootCoordinatorWithPersistentSessionActions() {
        let defaults = UserDefaults(suiteName: "PopPangAppTests.bootstrapBuildsRootCoordinatorWithPersistentSessionActions")!
        defaults.removePersistentDomain(forName: "PopPangAppTests.bootstrapBuildsRootCoordinatorWithPersistentSessionActions")

        let bootstrap = AppBootstrap.live(store: UserDefaultsStore(userDefaults: defaults))
        let coordinator = bootstrap.makeRootCoordinator()

        coordinator.completeOnboarding()
        #expect(defaults.object(forKey: "hasCompletedOnboarding") as? Bool == true)

        coordinator.completeAuthentication(userID: "user-777")
        #expect(defaults.string(forKey: "uuid") == "user-777")

        coordinator.logout()
        #expect(defaults.string(forKey: "uuid") == nil)
    }

    @Test
    func appDependencyRegistryBuildsLiveUsecases() {
        let registry = AppDependencyRegistry.live()

        #expect(registry.usecases.adminUsecase is AdminUsecaseImpl)
        #expect(registry.usecases.appleAuthUsecase is AppleAuthUsecaseImpl)
        #expect(registry.usecases.googleAuthUsecase is GoogleAuthUsecaseImpl)
        #expect(registry.usecases.kakaoAuthUsecase is KakaoAuthUsecaseImpl)
        #expect(registry.usecases.popupUsecase is PopupUsecaseImpl)
        #expect(registry.usecases.userUsecase is UserUsecaseImpl)
    }
}
