import Core
import Domain

public typealias FavoritesFeatureCoordinator = Coordinator<
    FavoritesFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
>

public enum FavoritesFeatureRoute: Hashable, Sendable {
    case alert(userUuid: String)
    case popupDetail(userUuid: String, popup: Popup)
    case reviewDetail([Review])
}
