import ComposableArchitecture
import Core
import Foundation
import HomeFeature
import AuthFeature
import PopupDetailFeature
import PopupRequestFeature
import PopupRequestManagementFeature

struct AppBootstrap {
    let sessionStorage: LocalSessionStorage
    let sessionClient: SessionClient
    let homePopupClient: HomePopupClient
    let popupDetailClient: PopupDetailClient
    let popupRequestClient: PopupRequestClient
    let popupRequestManagementClient: PopupRequestManagementClient
    let launchStateResolver: AppLaunchStateResolver
    let dependencies: AppDependencyRegistry

    static func live(
        store: KeyValueStoring = UserDefaultsStore()
    ) -> AppBootstrap {
        let sessionStorage = LocalSessionStorage(store: store)
        let dependencies = AppDependencyRegistry.live()
        let sessionClient = SessionClient.live(
            sessionStorage: sessionStorage,
            userUsecase: dependencies.usecases.userUsecase
        )
        let homePopupClient = HomePopupClient.live(
            popupUsecase: dependencies.usecases.popupUsecase
        )
        let popupDetailClient = PopupDetailClient.live(
            popupUsecase: dependencies.usecases.popupUsecase,
            adminUsecase: dependencies.usecases.adminUsecase
        )
        let popupRequestClient = PopupRequestClient.live(
            popupSubmissionUsecase: dependencies.usecases.popupSubmissionUsecase,
            userUsecase: dependencies.usecases.userUsecase
        )
        let popupRequestManagementClient = PopupRequestManagementClient.live(
            popupSubmissionUsecase: dependencies.usecases.popupSubmissionUsecase
        )
        let pushTokenStorage = PushTokenStorage(store: store)
        AppNotificationManager.shared.configure(
            sessionStorage: sessionStorage,
            pushTokenStorage: pushTokenStorage,
            userUsecase: dependencies.usecases.userUsecase
        )

        return AppBootstrap(
            sessionStorage: sessionStorage,
            sessionClient: sessionClient,
            homePopupClient: homePopupClient,
            popupDetailClient: popupDetailClient,
            popupRequestClient: popupRequestClient,
            popupRequestManagementClient: popupRequestManagementClient,
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
            $0.sessionClient = sessionClient
            $0.homePopupClient = homePopupClient
            $0.popupDetailClient = popupDetailClient
            $0.popupRequestClient = popupRequestClient
            $0.popupRequestManagementClient = popupRequestManagementClient
            $0.authFeatureClient = .live(
                kakaoAuthUsecase: dependencies.usecases.kakaoAuthUsecase,
                googleAuthUsecase: dependencies.usecases.googleAuthUsecase,
                appleAuthUsecase: dependencies.usecases.appleAuthUsecase,
                userUsecase: dependencies.usecases.userUsecase
            )
        }
    }
}
