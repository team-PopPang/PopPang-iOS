import OnboardingFeature
import SwiftUI

@MainActor
public final class OnboardingCoordinator: Coordinator {
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
            OnboardingFeatureRootView()

            Button("인증 플로우로 이동") {
                self.parent?.showAuthFlow()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Onboarding")
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
