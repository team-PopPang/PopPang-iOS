import ComposableArchitecture
import Core
import Foundation
import AuthFeature
import RootFeature

struct AppBootstrap {
    let sessionStorage: LocalSessionStorage
    let localSessionClient: LocalSessionClient
    let rootFeatureDependencies: RootFeatureDependencies
    let launchStateResolver: AppLaunchStateResolver
    let dependencies: AppDependencyRegistry

    static func live(
        store: KeyValueStoring = UserDefaultsStore()
    ) -> AppBootstrap {
        let sessionStorage = LocalSessionStorage(store: store)
        let dependencies = AppDependencyRegistry.live()
        let localSessionClient = LocalSessionClient.live(
            sessionStorage: sessionStorage,
            userUsecase: dependencies.usecases.userUsecase
        )
        let rootFeatureDependencies = RootFeatureDependencies(
            store: store,
            adminUsecase: dependencies.usecases.adminUsecase,
            popupUsecase: dependencies.usecases.popupUsecase,
            popupSubmissionUsecase: dependencies.usecases.popupSubmissionUsecase,
            userUsecase: dependencies.usecases.userUsecase
        )
        let pushTokenStorage = PushTokenStorage(store: store)
        AppNotificationManager.shared.configure(
            sessionStorage: sessionStorage,
            pushTokenStorage: pushTokenStorage,
            userUsecase: dependencies.usecases.userUsecase
        )

        return AppBootstrap(
            sessionStorage: sessionStorage,
            localSessionClient: localSessionClient,
            rootFeatureDependencies: rootFeatureDependencies,
            launchStateResolver: AppLaunchStateResolver(),
            dependencies: dependencies
        )
    }

    func makeAppStore() -> StoreOf<AppFeature> {
        Store(initialState: AppFeature.State()) {
            AppFeature(
                sessionStorage: sessionStorage,
                launchStateResolver: launchStateResolver
            )
        } withDependencies: {
            $0.localSessionClient = localSessionClient
            rootFeatureDependencies.configure(&$0)
            $0.authFeatureClient = .live(
                kakaoAuthUsecase: dependencies.usecases.kakaoAuthUsecase,
                googleAuthUsecase: dependencies.usecases.googleAuthUsecase,
                appleAuthUsecase: dependencies.usecases.appleAuthUsecase,
                userUsecase: dependencies.usecases.userUsecase
            )
        }
    }
}
