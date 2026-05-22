import Core
import HomeFeature
import PopupDetailFeature
import SearchFeature
import SwiftUI

@MainActor
public final class HomeCoordinator: Coordinator<
    HomeFeatureRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public func makeRootView() -> some View {
        HomeFeatureView()
            .navigationTitle("Home")
    }

    @ViewBuilder
    public func buildView(for route: HomeFeatureRoute) -> some View {
        switch route {
        case .search:
            SearchFeatureView()
        case .popupDetail:
            PopupDetailFeatureView()
        }
    }
}
