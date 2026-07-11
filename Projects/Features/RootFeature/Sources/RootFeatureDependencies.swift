import AlertFeature
import CalendarFeature
import ComposableArchitecture
import Core
import Domain
import FavoritesFeature
import HomeFeature
import MapFeature
import PopupDetailFeature
import PopupRequestFeature
import PopupRequestManagementFeature
import ProfileFeature
import SearchFeature

public struct RootFeatureDependencies {
    private let alertFeatureClient: AlertFeatureClient
    private let calendarFeatureClient: CalendarFeatureClient
    private let favoritesFeatureClient: FavoritesFeatureClient
    private let homePopupClient: HomePopupClient
    private let mapFeatureClient: MapFeatureClient
    private let popupDetailClient: PopupDetailClient
    private let popupRequestClient: PopupRequestClient
    private let popupRequestManagementClient: PopupRequestManagementClient
    private let profileFeatureClient: ProfileFeatureClient
    private let searchFeatureClient: SearchFeatureClient

    public init(
        store: KeyValueStoring,
        adminUsecase: AdminUsecaseProtocol,
        popupUsecase: PopupUsecaseProtocol,
        popupSubmissionUsecase: PopupSubmissionUsecaseProtocol,
        userUsecase: UserUsecaseProtocol
    ) {
        alertFeatureClient = .live(
            popupUsecase: popupUsecase,
            userUsecase: userUsecase,
            recentSearchStorage: RecentSearchStorage(store: store)
        )
        calendarFeatureClient = .live(popupUsecase: popupUsecase)
        favoritesFeatureClient = .live(popupUsecase: popupUsecase)
        homePopupClient = .live(popupUsecase: popupUsecase)
        mapFeatureClient = .live(popupUsecase: popupUsecase)
        popupDetailClient = .live(
            popupUsecase: popupUsecase,
            adminUsecase: adminUsecase
        )
        popupRequestClient = .live(
            popupSubmissionUsecase: popupSubmissionUsecase,
            userUsecase: userUsecase
        )
        popupRequestManagementClient = .live(
            popupSubmissionUsecase: popupSubmissionUsecase
        )
        profileFeatureClient = .live(userUsecase: userUsecase)
        searchFeatureClient = .live(
            popupUsecase: popupUsecase,
            recentSearchStorage: RecentSearchStorage(store: store)
        )
    }

    public func configure(_ values: inout DependencyValues) {
        values.alertFeatureClient = alertFeatureClient
        values.calendarFeatureClient = calendarFeatureClient
        values.favoritesFeatureClient = favoritesFeatureClient
        values.homePopupClient = homePopupClient
        values.mapFeatureClient = mapFeatureClient
        values.popupDetailClient = popupDetailClient
        values.popupRequestClient = popupRequestClient
        values.popupRequestManagementClient = popupRequestManagementClient
        values.profileFeatureClient = profileFeatureClient
        values.searchFeatureClient = searchFeatureClient
    }
}
