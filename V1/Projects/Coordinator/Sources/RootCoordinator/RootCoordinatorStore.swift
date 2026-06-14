import Observation
import Domain

public enum RootLaunchResult {
    case destination(RootDestination)
    case authenticated(User)
    case registrationRequired(User)
}

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
    public private(set) var mainTabCoordinator: MainTabCoordinator?
    private let actions: RootCoordinatorActions
    private let launch: (@MainActor () async -> RootLaunchResult)?
    private var mainTabSession: MainTabSession

    public init(
        destination: RootDestination = .launch,
        nextDestination: RootDestination = .onboarding,
        initialSession: MainTabSession = MainTabSession(userUuid: "demo-user"),
        actions: RootCoordinatorActions = .init(),
        launch: (@MainActor () async -> RootLaunchResult)? = nil
    ) {
        self.destination = destination
        self.nextDestination = nextDestination
        self.actions = actions
        self.launch = launch
        self.mainTabSession = initialSession
        self.onboardingCoordinator = OnboardingCoordinator()
        self.authFlowCoordinator = AuthFlowCoordinator()
        self.mainTabCoordinator = destination == .main ? MainTabCoordinator(session: initialSession) : nil

        onboardingCoordinator.parent = self
        authFlowCoordinator.parent = self
        mainTabCoordinator?.rootCoordinator = self
    }

    public func begin() async {
        guard destination == .launch else { return }

        guard let launch else {
            destination = nextDestination
            return
        }

        applyLaunchResult(await launch())
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
        makeMainTabCoordinator()
        destination = .main
    }

    public func showRegisterFlow() {
        destination = .register
    }

    public func markOnboardingCompleted() {
        actions.completeOnboarding()
    }

    public func completeOnboarding() {
        markOnboardingCompleted()
        destination = .auth
    }

    public func completeAuthentication(userID: String) {
        actions.authenticate(userID)
        makeMainTabCoordinator(session: MainTabSession(userUuid: userID))
        destination = .main
    }

    public func completeAuthentication(user: User) {
        if user.nickname == nil {
            actions.authenticate(user.userUuid)
            authFlowCoordinator.pendingRegistrationUser = user
            destination = .register
        } else {
            actions.authenticate(user.userUuid)
            makeMainTabCoordinator(
                session: MainTabSession(
                    userUuid: user.userUuid,
                    nickname: user.nickname ?? "닉네임",
                    isAlerted: user.isAlerted,
                    role: user.role
                )
            )
            destination = .main
        }
    }

    public func logout() {
        actions.logout()
        mainTabCoordinator = nil
        destination = .onboarding
    }

    private func applyLaunchResult(_ result: RootLaunchResult) {
        switch result {
        case .destination(let destination):
            if destination == .main {
                makeMainTabCoordinator()
            }
            self.destination = destination
        case .authenticated(let user):
            makeMainTabCoordinator(
                session: MainTabSession(
                    userUuid: user.userUuid,
                    nickname: user.nickname ?? "닉네임",
                    isAlerted: user.isAlerted,
                    role: user.role
                )
            )
            destination = .main
        case .registrationRequired(let user):
            authFlowCoordinator.pendingRegistrationUser = user
            destination = .register
        }
    }

    private func makeMainTabCoordinator(session: MainTabSession? = nil) {
        if let session {
            mainTabSession = session
        }

        let coordinator = MainTabCoordinator(session: mainTabSession)
        coordinator.rootCoordinator = self
        mainTabCoordinator = coordinator
    }
}
