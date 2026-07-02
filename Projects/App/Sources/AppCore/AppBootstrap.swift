import ComposableArchitecture
import CalendarFeature
import Core
import FavoritesFeature
import Foundation
import HomeFeature
import AuthFeature
import ProfileFeature
import PopupDetailFeature
import PopupRequestFeature
import PopupRequestManagementFeature

struct AppBootstrap {
    let sessionStorage: LocalSessionStorage
    let localSessionClient: LocalSessionClient
    let calendarFeatureClient: CalendarFeatureClient
    let favoritesFeatureClient: FavoritesFeatureClient
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
        let localSessionClient = LocalSessionClient.live(
            sessionStorage: sessionStorage,
            userUsecase: dependencies.usecases.userUsecase
        )
        let calendarFeatureClient = CalendarFeatureClient.live(
            popupUsecase: dependencies.usecases.popupUsecase
        )
        let favoritesFeatureClient = FavoritesFeatureClient.live(
            popupUsecase: dependencies.usecases.popupUsecase
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
            localSessionClient: localSessionClient,
            calendarFeatureClient: calendarFeatureClient,
            favoritesFeatureClient: favoritesFeatureClient,
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
            $0.localSessionClient = localSessionClient
            $0.calendarFeatureClient = calendarFeatureClient
            $0.favoritesFeatureClient = favoritesFeatureClient
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
            $0.profileFeatureClient = .live(
                userUsecase: dependencies.usecases.userUsecase
            )
        }
    }
}
