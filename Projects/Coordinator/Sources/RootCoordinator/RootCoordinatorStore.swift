import Observation
import Domain

public struct RootCoordinatorActions {
    public var completeOnboarding: @MainActor () -> Void
    public var authenticate: @MainActor (String) -> Void
    public var logout: @MainActor () -> Void

    public init(
        completeOnboarding: @escaping @MainActor () -> Void = {},
        authenticate: @escaping @MainActor (String) -> Void = { _ in },
        logout: @escaping @MainActor () -> Void = {}
    ) {
        self.completeOnboarding = completeOnboarding
        self.authenticate = authenticate
        self.logout = logout
    }
}

@Observable
@MainActor
public final class RootCoordinator: RootCoordinating {
    public var destination: RootDestination
    public let nextDestination: RootDestination
    public let onboardingCoordinator: OnboardingCoordinator
    public let authFlowCoordinator: AuthFlowCoordinator
    public let mainTabCoordinator: MainTabCoordinator
    private let actions: RootCoordinatorActions

    public init(
        destination: RootDestination = .launch,
        nextDestination: RootDestination = .onboarding,
        actions: RootCoordinatorActions = .init(),
        authDependencies: AuthFlowDependencies? = nil
    ) {
        self.destination = destination
        self.nextDestination = nextDestination
        self.actions = actions
        self.onboardingCoordinator = OnboardingCoordinator()
        self.authFlowCoordinator = AuthFlowCoordinator(dependencies: authDependencies)
        self.mainTabCoordinator = MainTabCoordinator()

        onboardingCoordinator.parent = self
        authFlowCoordinator.parent = self
        mainTabCoordinator.rootCoordinator = self
    }

    public func begin() {
        guard destination == .launch else { return }
        destination = nextDestination
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

    public func showRegisterFlow() {
        destination = .register
    }

    public func completeOnboarding() {
        actions.completeOnboarding()
        destination = .auth
    }

    public func completeAuthentication(userID: String) {
        actions.authenticate(userID)
        destination = .main
    }

    public func completeAuthentication(user: User) {
        if user.nickname == nil {
            authFlowCoordinator.pendingRegistrationUser = user
            destination = .register
        } else {
            completeAuthentication(userID: user.userUuid)
        }
    }

    public func logout() {
        actions.logout()
        destination = .auth
    }
}
