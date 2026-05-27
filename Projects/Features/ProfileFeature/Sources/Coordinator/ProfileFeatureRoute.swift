import Core

public typealias ProfileFeatureCoordinator = Coordinator<
    ProfileFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
>

public enum ProfileFeatureRoute: Hashable, Sendable {
    case alert(userUuid: String)
    case profileSetting(userUuid: String, nickname: String, isAlerted: Bool)
    case notifications
    case serviceTerms
}
