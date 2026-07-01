import ComposableArchitecture
import Core
import Domain

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
                && lhs.mainTabCore == rhs.mainTabCore
        }
    }

    enum Action {
        case launchTask
        case launchResolved(UserSession, AppRootDestination)
        case onboardingCompleted
        case authCompleted(User)
        case registerCompleted(User)
        case mainTab(MainTabFeature.Action)
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

            case .onboardingCompleted:
                sessionStorage.setOnboardingCompleted(true)
                state.destination = .auth
                return .none

            case .authCompleted(let user),
                    .registerCompleted(let user):
                applyAuthenticatedUser(user, state: &state)
                return .run { _ in
                    await sessionClient.saveUser(user)
                }

            case .mainTab(.delegate(.logout)):
                state.$session.withLock { $0 = UserSession() }
                state.mainTabCore = nil
                state.destination = .auth
                return .run { _ in
                    await sessionClient.clear()
                }

            case .mainTab:
                return .none
            }
        }
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

        if destination == .main, session.user != nil {
            state.mainTabCore = state.mainTabCore ?? .init(session: state.$session)
        } else {
            state.mainTabCore = nil
        }
    }

    func applyAuthenticatedUser(_ user: User, state: inout State) {
        configureAuthenticatedSession(user)
        state.$session.withLock { $0.user = user }

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
