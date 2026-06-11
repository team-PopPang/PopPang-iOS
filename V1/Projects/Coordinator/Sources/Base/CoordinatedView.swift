import Core
import SwiftUI

public struct CoordinatorContainer<
    Route: Hashable,
    Sheet: Identifiable,
    Overlay: Identifiable,
    FullScreen: Identifiable,
    BottomSheet: BottomSheetPresentingRoute,
    Content: View,
    Destination: View
>: View {
    @Bindable private var coordinator: Coordinator<Route, Sheet, Overlay, FullScreen, BottomSheet>
    private let content: () -> Content
    private let destination: (Route) -> Destination

    public init(
        coordinator: Coordinator<Route, Sheet, Overlay, FullScreen, BottomSheet>,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder destination: @escaping (Route) -> Destination
    ) {
        self.coordinator = coordinator
        self.content = content
        self.destination = destination
    }

    public var body: some View {
        NavigationStack(path: $coordinator.paths) {
            content()
                .navigationDestination(for: Route.self) { route in
                    destination(route)
                }
        }
        .environment(coordinator)
    }
}
