import AlertFeature
import CalendarFeatureV2
import ComposableArchitecture
import Core
import Domain
import FavoritesFeature
import HomeFeatureV2
import MapFeature
import PopPangRNFeature
import PopupDetailFeature
import ProfileFeature
import SearchFeature

public struct MainTabFeatureDependencies {
    private let alertFeatureClient: AlertFeatureClient
    private let calendarFeatureClient: CalendarFeatureClient
    private let favoritesFeatureClient: FavoritesFeatureClient
    private let homePopupClient: HomePopupClient
    private let mapFeatureClient: MapFeatureClient
    private let popupDetailClient: PopupDetailClient
    private let profileFeatureClient: ProfileFeatureClient
    private let searchFeatureClient: SearchFeatureClient

    /// - Parameter reactNativeAccessToken: React Native 화면(팝업 제보·제보 관리)이 V2 API를 부를 때 쓸 Access Token.
    ///   `forceRefresh`가 `true`면 갱신해 돌려준다. 로그아웃 상태이거나 갱신에 실패하면 `nil`.
    public init(
        store: Storing,
        adminUsecase: AdminUsecaseProtocol,
        popupUsecase: PopupUsecaseProtocol,
        userUsecase: UserUsecaseProtocol,
        reactNativeAccessToken: @escaping @Sendable (_ forceRefresh: Bool) async -> String?
    ) {
        PopPangRNHostAuth.setAccessTokenProvider(reactNativeAccessToken)

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
        values.profileFeatureClient = profileFeatureClient
        values.searchFeatureClient = searchFeatureClient
    }
}
