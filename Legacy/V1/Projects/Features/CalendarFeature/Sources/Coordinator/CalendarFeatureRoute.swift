import Core
import Domain

public typealias CalendarFeatureCoordinator = Coordinator<
    CalendarFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
>

public enum CalendarFeatureRoute: Hashable, Sendable {
    case alert(userUuid: String)
    case popupDetail(userUuid: String, popup: Popup)
    case reviewDetail([Review])
}
