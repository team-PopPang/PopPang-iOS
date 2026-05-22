import Core

public typealias FavoritesFeatureCoordinator = Coordinator<
    FavoritesFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
>

public enum FavoritesFeatureRoute: Hashable, Sendable {
    case alert
}
