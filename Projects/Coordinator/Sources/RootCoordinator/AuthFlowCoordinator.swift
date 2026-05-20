import AuthFeature
import SwiftUI

@MainActor
public final class AuthFlowCoordinator: Coordinator {
    public weak var parent: (any RootCoordinating)?
    public let navigationController: NavigationController

    public init() {
        self.navigationController = NavigationController()
    }

    public init(navigationController: NavigationController) {
        self.navigationController = navigationController
    }

    public var rootView: some View {
        VStack(spacing: 20) {
            AuthFeatureRootView()

            Button("메인 플로우로 이동") {
                self.parent?.showMainFlow()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Auth")
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
