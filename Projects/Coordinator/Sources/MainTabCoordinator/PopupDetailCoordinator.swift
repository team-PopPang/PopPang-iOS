import PopupDetailFeatureInterface
import SwiftUI

@MainActor
public final class PopupDetailCoordinator: Coordinator {
    public let navigationController: NavigationController

    public init(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public var rootView: some View {
        PopupDetailFeatureEntryView()
            .navigationTitle("Popup Detail")
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
