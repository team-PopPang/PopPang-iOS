import ComposableArchitecture
import AuthFeature
import Core
import Domain
import OnboardingFeature
import MainTabFeature

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
        var auth = AuthFeature.State()
        var registerFlow: RegisterFlowFeature.State?
        var onboarding = OnboardingFeature.State()
        var onboardingPath = StackState<OnboardingPath.State>()
        var mainTab: MainTabFeature.State?

        init(session: UserSession = .init()) {
            self._session = Shared(value: session)
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.destination == rhs.destination
                && lhs.session == rhs.session
                && lhs.auth == rhs.auth
                && lhs.registerFlow == rhs.registerFlow
                && lhs.onboarding == rhs.onboarding
                && lhs.mainTab == rhs.mainTab
        }
    }

    enum Action {
        case launchTask
        case launchResolved(UserSession, AppRootDestination)
        case auth(AuthFeature.Action)
        case registerFlow(RegisterFlowFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case onboardingPath(StackActionOf<OnboardingPath>)
        case authCompleted(User)
        case registerCompleted(User)
        case logoutFinished
        case mainTab(MainTabFeature.Action)
    }

    @Reducer
    enum OnboardingPath {
        case auth(AuthFeature)
    }

    @Dependency(\.localSessionClient) private var localSessionClient: LocalSessionClient
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
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }

        EmptyReducer()
            .ifLet(\.registerFlow, action: \.registerFlow) {
                RegisterFlowFeature()
            }

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

            case let .auth(.delegate(.authenticated(user))),
                 let .onboardingPath(.element(_, .auth(.delegate(.authenticated(user))))):
                return .send(.authCompleted(user))

            case let .registerFlow(.delegate(.completed(user))):
                return .send(.registerCompleted(user))

            case .authCompleted(let user),
                    .registerCompleted(let user):
                applyAuthenticatedUser(user, state: &state)
                return .run { _ in
                    await localSessionClient.saveUser(user)
                }

            case .mainTab(.delegate(.logout)):
                state.destination = .onboarding
                return .run { send in
                    await localSessionClient.clear()
                    await send(.logoutFinished)
                }

            case .logoutFinished:
                state.auth = .init()
                state.registerFlow = nil
                state.onboarding = .init()
                state.onboardingPath = StackState()
                state.mainTab = nil
                state.$session.withLock { $0 = UserSession() }
                return .none

            case .auth:
                return .none

            case .registerFlow:
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
            let session = await localSessionClient.load()
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
        state.auth = .init()
        state.registerFlow = nil
        state.onboarding = .init()
        state.onboardingPath = StackState()

        if destination == .main, session.user != nil {
            state.mainTab = state.mainTab ?? .init(session: state.$session)
        } else if destination == .register, let user = session.user {
            state.registerFlow = .init(user: user)
            state.mainTab = nil
        } else {
            state.mainTab = nil
        }
    }

    func applyAuthenticatedUser(_ user: User, state: inout State) {
        configureAuthenticatedSession(user)
        state.$session.withLock { $0.user = user }
        state.auth = .init()
        state.onboarding = .init()
        state.onboardingPath = StackState()

        if user.nickname == nil {
            state.mainTab = nil
            state.registerFlow = .init(user: user)
            state.destination = .register
        } else {
            state.registerFlow = nil
            state.mainTab = state.mainTab ?? .init(session: state.$session)
            state.destination = .main
        }
    }

    func configureAuthenticatedSession(_ user: User) {
        sessionStorage.setOnboardingCompleted(true)
        AppNotificationManager.shared.syncStoredToken(userUuid: user.userUuid)
    }
}
