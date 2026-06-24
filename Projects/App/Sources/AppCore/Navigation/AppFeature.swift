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
        var pendingRegistrationUser: User?
        var mainTab: MainTabFeature.State?

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.destination == rhs.destination
                && lhs.pendingRegistrationUser?.userUuid == rhs.pendingRegistrationUser?.userUuid
                && lhs.mainTab == rhs.mainTab
        }
    }

    enum Action {
        case launchTask
        case launchResolved(AppLaunchResolution)
        case onboardingCompleted
        case authCompleted(User)
        case registerCompleted(User)
        case mainTab(MainTabFeature.Action)
    }

    private let sessionStorage: AppSessionStorage
    private let launchStateResolver: AppLaunchStateResolver
    private let userUsecase: UserUsecaseProtocol

    init(
        sessionStorage: AppSessionStorage,
        launchStateResolver: AppLaunchStateResolver,
        userUsecase: UserUsecaseProtocol
    ) {
        self.sessionStorage = sessionStorage
        self.launchStateResolver = launchStateResolver
        self.userUsecase = userUsecase
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .launchTask:
                guard state.destination == .launch else { return .none }
                return resolveLaunch()

            case .launchResolved(let resolution):
                applyLaunchResolution(resolution, state: &state)
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
                sessionStorage.clearSession()
                state.mainTab = nil
                state.pendingRegistrationUser = nil
                state.destination = .onboarding
                return .none

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
        let userUsecase = userUsecase

        return .run { send in
            let latestSnapshot = sessionStorage.loadSnapshot()
            let resolution = await launchStateResolver.resolve(
                snapshot: latestSnapshot,
                userUsecase: userUsecase
            )

            await send(.launchResolved(resolution))
        }
    }

    func applyLaunchResolution(_ resolution: AppLaunchResolution, state: inout State) {
        switch resolution {
        case .destination(let destination):
            if destination == .main {
                let snapshot = sessionStorage.loadSnapshot()
                state.mainTab = MainTabFeature.State(
                    session: MainTabSession(userUuid: snapshot.userID ?? "demo-user")
                )
            }
            state.destination = destination

        case .authenticated(let user):
            configureAuthenticatedSession(user)
            state.pendingRegistrationUser = nil
            state.mainTab = MainTabFeature.State(session: MainTabSession(user: user))
            state.destination = .main

        case .registrationRequired(let user):
            configureAuthenticatedSession(user)
            state.pendingRegistrationUser = user
            state.mainTab = nil
            state.destination = .register
        }
    }

    func applyAuthenticatedUser(_ user: User, state: inout State) {
        configureAuthenticatedSession(user)

        if user.nickname == nil {
            state.pendingRegistrationUser = user
            state.mainTab = nil
            state.destination = .register
        } else {
            state.pendingRegistrationUser = nil
            state.mainTab = MainTabFeature.State(session: MainTabSession(user: user))
            state.destination = .main
        }
    }

    func configureAuthenticatedSession(_ user: User) {
        sessionStorage.setOnboardingCompleted(true)
        sessionStorage.saveUserID(user.userUuid)
        AppNotificationManager.shared.syncStoredToken(userUuid: user.userUuid)
    }
}

extension MainTabSession {
    init(user: User) {
        self.init(
            userUuid: user.userUuid,
            nickname: user.nickname ?? "닉네임",
            isAlerted: user.isAlerted,
            role: user.role
        )
    }
}
