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

    public init(
        store: Storing,
        adminUsecase: AdminUsecaseProtocol,
        popupUsecase: PopupUsecaseProtocol,
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
        profileFeatureClient = .live(userUsecase: userUsecase)
        searchFeatureClient = .live(
            popupUsecase: popupUsecase,
            recentSearchStorage: RecentSearchStorage(store: store)
        )
    }

    /// React Native 화면(팝업 제보·제보 관리)이 V2 API를 부를 때 쓸 Access Token 공급자를 앱 전체에 한 번 등록한다.
    ///
    /// RN 네이티브 모듈(`PopPangHostAuth`)이 전역으로 들고 있으므로 마지막에 등록한 공급자를 쓴다.
    /// 앱 target은 `PopPangRNFeature`에 직접 의존하지 않아 이 함수로 넘긴다. 인자는 `PopPangRNHostAuth.setAccessTokenProvider(_:)`를 본다.
    public static func registerReactNativeAccessTokenProvider(
        _ provider: @escaping @Sendable (
            _ rejectedAccessToken: String?,
            _ expired: Bool
        ) async -> (accessToken: String?, temporaryFailure: Bool)
    ) {
        PopPangRNHostAuth.setAccessTokenProvider(provider)
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
