import CalendarFeature
import Core
import SwiftUI

@MainActor
public final class CalendarCoordinator: Coordinator<
    EmptyRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public func makeRootView() -> some View {
        CalendarFeatureView()
            .navigationTitle("Calendar")
    }

    @ViewBuilder
    public func buildView(for route: EmptyRoute) -> some View {
        EmptyView()
    }
}
