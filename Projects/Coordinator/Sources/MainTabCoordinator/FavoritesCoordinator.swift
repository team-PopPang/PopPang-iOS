import FavoritesFeature
import SwiftUI

@MainActor
public final class FavoritesCoordinator: Coordinator {
    public let navigationController: NavigationController

    public init() {
        self.navigationController = NavigationController()
    }

    public init(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public var rootView: some View {
        FavoritesFeatureRootView()
            .navigationTitle("Favorites")
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
