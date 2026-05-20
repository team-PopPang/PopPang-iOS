import Observation

@Observable
@MainActor
public final class RootCoordinator: RootCoordinating {
    public var destination: RootDestination
    public let onboardingCoordinator: OnboardingCoordinator
    public let authFlowCoordinator: AuthFlowCoordinator
    public let mainTabCoordinator: MainTabCoordinator

    public init(destination: RootDestination = .launch) {
        self.destination = destination
        self.onboardingCoordinator = OnboardingCoordinator()
        self.authFlowCoordinator = AuthFlowCoordinator()
        self.mainTabCoordinator = MainTabCoordinator()

        onboardingCoordinator.parent = self
        authFlowCoordinator.parent = self
        mainTabCoordinator.rootCoordinator = self
    }

    public func showLaunch() {
        destination = .launch
    }

    public func showOnboarding() {
        destination = .onboarding
    }

    public func showAuthFlow() {
        destination = .auth
    }

    public func showMainFlow() {
        destination = .main
    }
}
