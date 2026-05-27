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
    func launchStateResolverKeepsUnauthenticatedUsersInOnboardingFlowLikeV0() {
        let resolver = AppLaunchStateResolver()
        let snapshot = AppSessionSnapshot(
            userID: nil,
            hasCompletedOnboarding: true,
            fcmToken: nil,
            deepLinkPopupID: nil
        )

        #expect(resolver.resolve(snapshot: snapshot) == .onboarding)
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
    func launchStateResolverAuthenticatesStoredUserLikeV0() async {
        let resolver = AppLaunchStateResolver()
        let user = User.demo(userUuid: "user-123", nickname: "팝팡")
        let snapshot = AppSessionSnapshot(
            userID: "user-123",
            hasCompletedOnboarding: true,
            fcmToken: nil,
            deepLinkPopupID: nil
        )

        let resolution = await resolver.resolve(
            snapshot: snapshot,
            userUsecase: MockUserUsecase(autoLoginResult: .success(user))
        )

        guard case .authenticated(let resolvedUser) = resolution else {
            Issue.record("Expected authenticated launch resolution")
            return
        }
        #expect(resolvedUser.userUuid == "user-123")
    }

    @Test
    func launchStateResolverRoutesNewUserToRegisterLikeV0() async {
        let resolver = AppLaunchStateResolver()
        let user = User.demo(userUuid: "new-user", nickname: nil)
        let snapshot = AppSessionSnapshot(
            userID: "new-user",
            hasCompletedOnboarding: true,
            fcmToken: nil,
            deepLinkPopupID: nil
        )

        let resolution = await resolver.resolve(
            snapshot: snapshot,
            userUsecase: MockUserUsecase(autoLoginResult: .success(user))
        )

        guard case .registrationRequired(let resolvedUser) = resolution else {
            Issue.record("Expected registration launch resolution")
            return
        }
        #expect(resolvedUser.userUuid == "new-user")
    }

    @Test
    func launchStateResolverFallsBackToOnboardingWhenAutoLoginFailsLikeV0() async {
        let resolver = AppLaunchStateResolver()
        let snapshot = AppSessionSnapshot(
            userID: "expired-user",
            hasCompletedOnboarding: true,
            fcmToken: nil,
            deepLinkPopupID: nil
        )

        let resolution = await resolver.resolve(
            snapshot: snapshot,
            userUsecase: MockUserUsecase(autoLoginResult: .failure(MockError.autoLoginFailed))
        )

        guard case .destination(let destination) = resolution else {
            Issue.record("Expected destination launch resolution")
            return
        }
        #expect(destination == .onboarding)
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
    func notificationManagerStoresFCMTokenLikeV0NotificationManager() {
        let defaults = UserDefaults(suiteName: "PopPangAppTests.notificationManagerStoresFCMTokenLikeV0NotificationManager")!
        defaults.removePersistentDomain(forName: "PopPangAppTests.notificationManagerStoresFCMTokenLikeV0NotificationManager")

        let storage = AppSessionStorage(store: UserDefaultsStore(userDefaults: defaults))
        let manager = AppNotificationManager(sessionStorage: storage)

        manager.messaging("messaging", didReceiveRegistrationToken: "fcm-token-123")

        #expect(defaults.string(forKey: "fcmToken") == "fcm-token-123")
    }

    @Test
    @MainActor
    func deepLinkHandlerStoresKakaoSharePopupIDLikeV0SceneDelegate() {
        let defaults = UserDefaults(suiteName: "PopPangAppTests.deepLinkHandlerStoresKakaoSharePopupIDLikeV0SceneDelegate")!
        defaults.removePersistentDomain(forName: "PopPangAppTests.deepLinkHandlerStoresKakaoSharePopupIDLikeV0SceneDelegate")

        let handler = AppDeepLinkHandler(store: UserDefaultsStore(userDefaults: defaults))
        let didHandle = handler.handleIncomingURL(URL(string: "kakao57dbc12345://kakaolink?popupId=popup-777")!)

        #expect(didHandle)
        #expect(defaults.string(forKey: "deeplinkPopupId") == "popup-777")
    }

    @Test
    @MainActor
    func deepLinkHandlerStoresUniversalLinkPopupIDLikeV0SceneDelegate() {
        let defaults = UserDefaults(suiteName: "PopPangAppTests.deepLinkHandlerStoresUniversalLinkPopupIDLikeV0SceneDelegate")!
        defaults.removePersistentDomain(forName: "PopPangAppTests.deepLinkHandlerStoresUniversalLinkPopupIDLikeV0SceneDelegate")

        let handler = AppDeepLinkHandler(store: UserDefaultsStore(userDefaults: defaults))
        let didHandle = handler.handleIncomingURL(URL(string: "https://poppang.co.kr/popup/popup-888")!)

        #expect(didHandle)
        #expect(defaults.string(forKey: "deeplinkPopupId") == "popup-888")
    }

    @Test
    @MainActor
    func bootstrapPersistsRegistrationStageWhenLoginNeedsSignup() {
        let defaults = UserDefaults(suiteName: "PopPangAppTests.bootstrapPersistsRegistrationStageWhenLoginNeedsSignup")!
        defaults.removePersistentDomain(forName: "PopPangAppTests.bootstrapPersistsRegistrationStageWhenLoginNeedsSignup")

        let bootstrap = AppBootstrap.live(store: UserDefaultsStore(userDefaults: defaults))
        let coordinator = bootstrap.makeRootCoordinator()

        coordinator.completeAuthentication(user: User.demo(userUuid: "register-user", nickname: nil))

        #expect(coordinator.destination == .register)
        #expect(defaults.object(forKey: "hasCompletedOnboarding") as? Bool == true)
        #expect(defaults.string(forKey: "uuid") == "register-user")
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

private enum MockError: Error {
    case autoLoginFailed
}

private struct MockUserUsecase: UserUsecaseProtocol {
    let autoLoginResult: Result<User, Error>

    func checkNickname(nickname: String) async throws -> Bool {
        false
    }

    func autoLogin(userUuid: String) async throws -> User {
        try autoLoginResult.get()
    }

    func getRecommandList() async throws -> [Recommend] {
        []
    }

    func hardDeleteUser(userUuid: String) async throws {}

    func getAlertKeywordList(userUuid: String) async throws -> [Keyword] {
        []
    }

    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {}

    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {}

    func alertStatus(userUuid: String, isAlerted: Bool) async throws {}

    func updateNickname(userUuid: String, newNickname: String) async throws {}

    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        true
    }

    func updateFcmToken(userUuid: String, fcmToken: String) async throws {}
}

private extension User {
    static func demo(userUuid: String, nickname: String?) -> User {
        User(
            userUuid: userUuid,
            uid: "uid-\(userUuid)",
            provider: "KAKAO",
            email: nil,
            nickname: nickname,
            role: "USER",
            isAlerted: false,
            fcmToken: nil,
            alertKeywordList: nil,
            recommendList: nil
        )
    }
}
