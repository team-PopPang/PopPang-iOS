import Core

public typealias ProfileFeatureCoordinator = Coordinator<
    ProfileFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
>

public enum ProfileFeatureRoute: Hashable, Sendable {
    case alert
    case profileSetting
    case notifications
    case serviceTerms
}
