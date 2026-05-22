import Core
import FavoritesFeature
import SwiftUI

@MainActor
public final class FavoritesCoordinator: Coordinator<
    EmptyRoute,
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
    public func buildView(for route: EmptyRoute) -> some View {
        EmptyView()
    }
}
