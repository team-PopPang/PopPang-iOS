import AlertFeature
import Core
import FavoritesFeature
import SwiftUI

@MainActor
public final class FavoritesCoordinator: Coordinator<
    FavoritesFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public func makeRootView() -> some View {
        FavoritesFeatureView()
            .navigationTitle("Favorites")
    }

    @ViewBuilder
    public func buildView(for route: FavoritesFeatureRoute) -> some View {
        switch route {
        case .alert:
            AlertFeatureView()
        }
    }
}
