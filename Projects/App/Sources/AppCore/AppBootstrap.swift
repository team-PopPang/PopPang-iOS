import ComposableArchitecture
import Core
import Foundation
import AuthFeature
import MainTabFeature

struct AppBootstrap {
    let sessionStorage: LocalSessionStorage
    let localSessionClient: LocalSessionClient
    let mainTabFeatureDependencies: MainTabFeatureDependencies
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
        let mainTabFeatureDependencies = MainTabFeatureDependencies(
            store: store,
            adminUsecase: dependencies.usecases.adminUsecase,
            popupUsecase: dependencies.usecases.popupUsecase,
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
            mainTabFeatureDependencies: mainTabFeatureDependencies,
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
            mainTabFeatureDependencies.configure(&$0)
            $0.authFeatureClient = .live(
                kakaoAuthUsecase: dependencies.usecases.kakaoAuthUsecase,
                googleAuthUsecase: dependencies.usecases.googleAuthUsecase,
                appleAuthUsecase: dependencies.usecases.appleAuthUsecase,
                userUsecase: dependencies.usecases.userUsecase
            )
        }
    }
}
