import ComposableArchitecture
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
        let pushTokenStorage = PushTokenStorage(store: store)
        let dependencies = AppDependencyRegistry.live()
        AppNotificationManager.shared.configure(
            sessionStorage: sessionStorage,
            pushTokenStorage: pushTokenStorage,
            userUsecase: dependencies.usecases.userUsecase
        )

        return AppBootstrap(
            sessionStorage: sessionStorage,
            launchStateResolver: AppLaunchStateResolver(),
            dependencies: dependencies
        )
    }

    func makeAppStore() -> StoreOf<AppFeature> {
        Store(initialState: AppFeature.State()) {
            AppFeature(
                sessionStorage: sessionStorage,
                launchStateResolver: launchStateResolver,
                userUsecase: dependencies.usecases.userUsecase
            )
        }
    }
}
