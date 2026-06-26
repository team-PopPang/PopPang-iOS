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

@MainActor
public final class RootCoordinator: Coordinator<
    RootDestination,
    MainTabRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    MainTabFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public let tabs: [MainTab]
    public var selectedTab: MainTab
    public var pendingRegistrationUser: User?
    public private(set) var session: MainTabSession

    private let nextDestination: RootDestination
    private let actions: RootCoordinatorActions
    private let launch: (@MainActor () async -> RootLaunchResult)?

    public init(
        destination: RootDestination = .launch,
        nextDestination: RootDestination = .onboarding,
        initialSession: MainTabSession = MainTabSession(userUuid: "demo-user"),
        actions: RootCoordinatorActions = .init(),
        launch: (@MainActor () async -> RootLaunchResult)? = nil
    ) {
        self.tabs = MainTab.allCases
        self.selectedTab = .home
        self.pendingRegistrationUser = nil
        self.session = initialSession
        self.nextDestination = nextDestination
        self.actions = actions
        self.launch = launch
        super.init(root: destination)
    }

    public func begin() async {
        guard root == .launch else { return }

        guard let launch else {
            switchToRoot(nextDestination)
            return
        }

        applyLaunchResult(await launch())
    }

    public func completeOnboarding() {
        actions.completeOnboarding()
        switchToRoot(.auth)
    }

    public func completeAuthentication(userID: String) {
        actions.authenticate(userID)
        session = MainTabSession(userUuid: userID)
        pendingRegistrationUser = nil
        selectedTab = .home
        switchToRoot(.main)
    }

    public func completeAuthentication(user: User) {
        actions.authenticate(user.userUuid)

        guard let nickname = user.nickname else {
            pendingRegistrationUser = user
            switchToRoot(.register)
            return
        }

        session = MainTabSession(
            userUuid: user.userUuid,
            nickname: nickname,
            isAlerted: user.isAlerted,
            role: user.role
        )
        pendingRegistrationUser = nil
        selectedTab = .home
        switchToRoot(.main)
    }

    public func logout() {
        actions.logout()
        pendingRegistrationUser = nil
        selectedTab = .home
        session = MainTabSession(userUuid: "demo-user")
        switchToRoot(.onboarding)
    }

    public func select(_ tab: MainTab) {
        selectedTab = tab
    }

    public func updateSession(_ session: MainTabSession) {
        self.session = session
    }

    private func applyLaunchResult(_ result: RootLaunchResult) {
        switch result {
        case .destination(let destination):
            switchToRoot(destination)
        case .authenticated(let user):
            completeAuthentication(user: user)
        case .registrationRequired(let user):
            pendingRegistrationUser = user
            switchToRoot(.register)
        }
    }
}
