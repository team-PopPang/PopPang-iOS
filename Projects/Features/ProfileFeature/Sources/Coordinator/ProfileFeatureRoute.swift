import Core
import Domain

public typealias ProfileFeatureCoordinator = Coordinator<
    ProfileFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
>

public enum ProfileFeatureRoute: Hashable, Sendable {
    case alert(userUuid: String)
    case popupDetail(userUuid: String, popup: Popup)
    case profileSetting(userUuid: String, nickname: String, isAlerted: Bool)
    case notifications
    case serviceTerms
    case reviewDetail([Review])
}
