import SearchFeatureInterface
import SwiftUI

@MainActor
public final class SearchCoordinator: Coordinator {
    public let navigationController: NavigationController

    public init(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public var rootView: some View {
        SearchFeatureEntryView()
            .navigationTitle("Search")
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
