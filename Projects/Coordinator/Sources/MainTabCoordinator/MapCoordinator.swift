import MapFeature
import SwiftUI

@MainActor
public final class MapCoordinator: Coordinator {
    public let navigationController: NavigationController

    public init() {
        self.navigationController = NavigationController()
    }

    public init(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public var rootView: some View {
        MapFeatureRootView()
            .navigationTitle("Map")
            .navigationDestination(for: PlaceholderRoute.self, destination: coordinate(_:))
    }

    @ViewBuilder
    public func coordinate(_ route: PlaceholderRoute) -> some View {
        switch route {
        case .placeholder:
            EmptyView()
        }
    }
}
