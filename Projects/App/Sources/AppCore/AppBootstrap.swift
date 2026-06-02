import Coordinator
import Core
import Foundation

struct AppBootstrap {
    let sessionStorage: AppSessionStorage
    let launchStateResolver: AppLaunchStateResolver
    let dependencies: AppDependencyRegistry

    static func live(
        store: KeyValueStoring = UserDefaultsStore()
    ) -> AppBootstrap {
        let sessionStorage = AppSessionStorage(store: store)
        let dependencies = AppDependencyRegistry.live()
        AppNotificationManager.shared.configure(
            sessionStorage: sessionStorage,
            userUsecase: dependencies.usecases.userUsecase
        )

        return AppBootstrap(
            sessionStorage: sessionStorage,
            launchStateResolver: AppLaunchStateResolver(),
            dependencies: dependencies
        )
    }

    @MainActor
    func makeRootCoordinator() -> RootCoordinator {
        let snapshot = sessionStorage.loadSnapshot()
        let nextDestination = launchStateResolver.resolve(snapshot: snapshot)
        let userUsecase = dependencies.usecases.userUsecase
        let actions = RootCoordinatorActions(
            completeOnboarding: {
                sessionStorage.setOnboardingCompleted(true)
            },
            authenticate: { userID in
                sessionStorage.setOnboardingCompleted(true)
                sessionStorage.saveUserID(userID)
                AppNotificationManager.shared.syncStoredToken(userUuid: userID)
            },
            logout: {
                sessionStorage.clearSession()
            }
        )
        let launch: @MainActor () async -> RootLaunchResult = {
            let latestSnapshot = sessionStorage.loadSnapshot()
            let resolution = await launchStateResolver.resolve(
                snapshot: latestSnapshot,
                userUsecase: userUsecase
            )

            switch resolution {
            case .destination(let destination):
                if latestSnapshot.hasAuthenticatedUser {
                    sessionStorage.clearSession()
                }
                return .destination(destination)
            case .authenticated(let user):
                sessionStorage.setOnboardingCompleted(true)
                sessionStorage.saveUserID(user.userUuid)
                return .authenticated(user)
            case .registrationRequired(let user):
                sessionStorage.setOnboardingCompleted(true)
                sessionStorage.saveUserID(user.userUuid)
                return .registrationRequired(user)
            }
        }

        return RootCoordinator(
            destination: .launch,
            nextDestination: nextDestination,
            initialSession: MainTabSession(userUuid: snapshot.userID ?? "demo-user"),
            actions: actions,
            launch: launch
        )
    }
}
