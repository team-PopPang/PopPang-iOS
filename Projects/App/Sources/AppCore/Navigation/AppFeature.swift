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
        var session = SessionState()
        var mainTabCore: MainTabFeature.CoreState?

        var mainTab: MainTabFeature.State? {
            get {
                guard session.user != nil, let mainTabCore else { return nil }
                return MainTabFeature.State(
                    session: session,
                    core: mainTabCore
                )
            }
            set {
                guard let newValue else {
                    mainTabCore = nil
                    return
                }

                session = newValue.session
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
        case launchResolved(SessionState, AppRootDestination)
        case onboardingCompleted
        case authCompleted(User)
        case registerCompleted(User)
        case mainTab(MainTabFeature.Action)
    }

    private let sessionStorage: AppSessionStorage
    private let sessionClient: SessionClient
    private let launchStateResolver: AppLaunchStateResolver

    init(
        sessionStorage: AppSessionStorage,
        sessionClient: SessionClient,
        launchStateResolver: AppLaunchStateResolver
    ) {
        self.sessionStorage = sessionStorage
        self.sessionClient = sessionClient
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
                return .none

            case .mainTab(.delegate(.logout)):
                state.session = SessionState()
                state.mainTabCore = nil
                state.destination = .auth
                let sessionClient = sessionClient
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
        let sessionClient = sessionClient
        let launchStateResolver = launchStateResolver

        return .run { send in
            let latestSnapshot = sessionStorage.loadSnapshot()
            let session = await sessionClient.load()
            let destination = launchStateResolver.resolve(
                snapshot: latestSnapshot,
                session: session
            )

            await send(.launchResolved(session, destination))
        }
    }

    func applyLaunchState(
        session: SessionState,
        destination: AppRootDestination,
        state: inout State
    ) {
        state.session = session
        state.destination = destination

        if destination == .main, session.user != nil {
            state.mainTabCore = state.mainTabCore ?? .init(session: session)
        } else {
            state.mainTabCore = nil
        }
    }

    func applyAuthenticatedUser(_ user: User, state: inout State) {
        configureAuthenticatedSession(user)
        state.session.user = user

        if user.nickname == nil {
            state.mainTabCore = nil
            state.destination = .register
        } else {
            state.mainTabCore = state.mainTabCore ?? .init(session: state.session)
            state.destination = .main
        }
    }

    func configureAuthenticatedSession(_ user: User) {
        sessionStorage.setOnboardingCompleted(true)
        AppNotificationManager.shared.syncStoredToken(userUuid: user.userUuid)
        let sessionClient = sessionClient
        Task {
            await sessionClient.saveUser(user)
        }
    }
}
