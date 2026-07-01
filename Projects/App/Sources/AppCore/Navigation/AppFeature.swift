import ComposableArchitecture
import Core
import Domain
import OnboardingFeature

enum AppRootDestination: Equatable, Sendable {
    case launch
    case onboarding
    case auth
    case register
    case main
}

enum AppLaunchResolution {
    case destination(AppRootDestination)
    case authenticated(User)
    case registrationRequired(User)
}

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        var destination: AppRootDestination = .launch
        @Shared var session: UserSession
        var onboarding = OnboardingFeature.State()
        var onboardingPath = StackState<OnboardingPath.State>()
        var mainTabCore: MainTabFeature.CoreState?

        init(session: UserSession = .init()) {
            self._session = Shared(value: session)
        }

        var mainTab: MainTabFeature.State? {
            get {
                guard session.user != nil, let mainTabCore else { return nil }
                return MainTabFeature.State(
                    session: $session,
                    core: mainTabCore
                )
            }
            set {
                guard let newValue else {
                    mainTabCore = nil
                    return
                }

                mainTabCore = newValue.core
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.destination == rhs.destination
                && lhs.session == rhs.session
                && lhs.onboarding == rhs.onboarding
                && lhs.mainTabCore == rhs.mainTabCore
        }
    }

    enum Action {
        case launchTask
        case launchResolved(UserSession, AppRootDestination)
        case onboarding(OnboardingFeature.Action)
        case onboardingPath(StackActionOf<OnboardingPath>)
        case authCompleted(User)
        case registerCompleted(User)
        case logoutFinished
        case mainTab(MainTabFeature.Action)
    }

    @Reducer
    enum OnboardingPath {
        case auth(OnboardingAuthDestinationFeature)
    }

    @Dependencies.Dependency(\.sessionClient) private var sessionClient: SessionClient
    private let sessionStorage: LocalSessionStorage
    private let launchStateResolver: AppLaunchStateResolver

    init(
        sessionStorage: LocalSessionStorage,
        launchStateResolver: AppLaunchStateResolver
    ) {
        self.sessionStorage = sessionStorage
        self.launchStateResolver = launchStateResolver
    }

    var body: some ReducerOf<Self> {
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Reduce { state, action in
            switch action {
            case .launchTask:
                guard state.destination == .launch else { return .none }
                return resolveLaunch()

            case .launchResolved(let session, let destination):
                applyLaunchState(
                    session: session,
                    destination: destination,
                    state: &state
                )
                return .none

            case .onboarding(.delegate(.authRequested)):
                sessionStorage.setOnboardingCompleted(true)
                if state.onboardingPath.isEmpty {
                    state.onboardingPath.append(.auth(.init()))
                }
                return .none

            case let .onboardingPath(.element(_, .auth(.delegate(.loginSucceeded(user))))):
                return .send(.authCompleted(user))

            case .authCompleted(let user),
                    .registerCompleted(let user):
                applyAuthenticatedUser(user, state: &state)
                return .run { _ in
                    await sessionClient.saveUser(user)
                }

            case .mainTab(.delegate(.logout)):
                state.destination = .onboarding
                return .run { send in
                    await sessionClient.clear()
                    await send(.logoutFinished)
                }

            case .logoutFinished:
                state.onboarding = .init()
                state.onboardingPath = StackState()
                state.mainTabCore = nil
                state.$session.withLock { $0 = UserSession() }
                return .none

            case .onboardingPath:
                return .none

            case .onboarding:
                return .none

            case .mainTab:
                return .none
            }
        }
        .forEach(\.onboardingPath, action: \.onboardingPath)
        .ifLet(\.mainTab, action: \.mainTab) {
            MainTabFeature()
        }
    }
}

private extension AppFeature {
    func resolveLaunch() -> Effect<Action> {
        let sessionStorage = sessionStorage
        let launchStateResolver = launchStateResolver

        return .run { send in
            let latestSnapshot = sessionStorage.loadSnapshot()
            let session = await sessionClient.load().userSession
            let destination = launchStateResolver.resolve(
                snapshot: latestSnapshot,
                session: session
            )

            await send(.launchResolved(session, destination))
        }
    }

    func applyLaunchState(
        session: UserSession,
        destination: AppRootDestination,
        state: inout State
    ) {
        state.$session.withLock { $0 = session }
        state.destination = destination
        state.onboarding = .init()
        state.onboardingPath = StackState()

        if destination == .main, session.user != nil {
            state.mainTabCore = state.mainTabCore ?? .init(session: state.$session)
        } else {
            state.mainTabCore = nil
        }
    }

    func applyAuthenticatedUser(_ user: User, state: inout State) {
        configureAuthenticatedSession(user)
        state.$session.withLock { $0.user = user }
        state.onboarding = .init()
        state.onboardingPath = StackState()

        if user.nickname == nil {
            state.mainTabCore = nil
            state.destination = .register
        } else {
            state.mainTabCore = state.mainTabCore ?? .init(session: state.$session)
            state.destination = .main
        }
    }

    func configureAuthenticatedSession(_ user: User) {
        sessionStorage.setOnboardingCompleted(true)
        AppNotificationManager.shared.syncStoredToken(userUuid: user.userUuid)
    }
}

@Reducer
struct OnboardingAuthDestinationFeature {
    @ObservableState
    struct State: Equatable {
        init() {}
    }

    enum Action: Equatable {
        case loginSucceeded(User)
        case delegate(Delegate)

        enum Delegate: Equatable {
            case loginSucceeded(User)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { _, action in
            switch action {
            case .loginSucceeded(let user):
                return .send(.delegate(.loginSucceeded(user)))
            case .delegate:
                return .none
            }
        }
    }
}
