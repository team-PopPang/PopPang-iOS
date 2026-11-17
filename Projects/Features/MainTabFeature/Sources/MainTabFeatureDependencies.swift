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

    /// React Native 런타임(팝업 제보·제보 관리 화면)을 시작하고, RN이 V2 API용 Access Token을 요청할 때 쓸 공급자를 연결한다.
    ///
    /// 앱을 시작할 때 한 번 부른다. 앱 target은 `PopPangRNFeature`에 직접 의존하지 않아 이 함수로 넘긴다.
    /// 인자는 `PopPangRNAccessTokenProvider`를 본다.
    @MainActor
    public static func startReactNative(accessTokenProvider: @escaping PopPangRNAccessTokenProvider) {
        PopPangRNRuntime.start(accessTokenProvider: accessTokenProvider)
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
