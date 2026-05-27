import Core
import Domain

public typealias MapFeatureCoordinator = Coordinator<
    MapFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    MapBottomSheetRoute
>

public enum MapFeatureRoute: Hashable, Sendable {
    case popupDetail(userUuid: String, popup: Popup)
    case reviewDetail([Review])
}
