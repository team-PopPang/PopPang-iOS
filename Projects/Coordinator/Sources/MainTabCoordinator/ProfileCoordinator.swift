import ProfileFeature
import SwiftUI

@MainActor
public protocol ProfileCoordinatorParent: AnyObject {
    func showAuthFlow()
}

@MainActor
public final class ProfileCoordinator: Coordinator {
    public weak var parent: (any ProfileCoordinatorParent)?
    public let navigationController: NavigationController

    public init() {
        self.navigationController = NavigationController()
    }

    public init(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public var rootView: some View {
        VStack(spacing: 20) {
            ProfileFeatureRootView()

            Button("로그아웃") {
                self.parent?.showAuthFlow()
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Profile")
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
