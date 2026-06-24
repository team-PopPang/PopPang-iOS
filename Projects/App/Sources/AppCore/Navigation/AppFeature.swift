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
        var currentUser: User?
        var mainTabCore: MainTabFeature.CoreState?

        var mainTab: MainTabFeature.State? {
            get {
                guard let currentUser, let mainTabCore else { return nil }
                return MainTabFeature.State(
                    currentUser: currentUser,
                    core: mainTabCore
                )
            }
            set {
                guard let newValue else {
                    mainTabCore = nil
                    return
                }

                currentUser = newValue.currentUser
                mainTabCore = newValue.core
            }
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.destination == rhs.destination
                && AppCurrentUserSnapshot(lhs.currentUser) == AppCurrentUserSnapshot(rhs.currentUser)
                && lhs.mainTabCore == rhs.mainTabCore
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
                state.currentUser = nil
                state.mainTabCore = nil
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
            state.currentUser = nil
            state.mainTabCore = nil
            state.destination = destination

        case .authenticated(let user):
            configureAuthenticatedSession(user)
            state.currentUser = user
            if user.nickname == nil {
                state.mainTabCore = nil
                state.destination = .register
            } else {
                state.mainTabCore = state.mainTabCore ?? .init()
                state.destination = .main
            }

        case .registrationRequired(let user):
            configureAuthenticatedSession(user)
            state.currentUser = user
            state.mainTabCore = nil
            state.destination = .register
        }
    }

    func applyAuthenticatedUser(_ user: User, state: inout State) {
        configureAuthenticatedSession(user)
        state.currentUser = user

        if user.nickname == nil {
            state.mainTabCore = nil
            state.destination = .register
        } else {
            state.mainTabCore = state.mainTabCore ?? .init()
            state.destination = .main
        }
    }

    func configureAuthenticatedSession(_ user: User) {
        sessionStorage.setOnboardingCompleted(true)
        sessionStorage.saveUserID(user.userUuid)
        AppNotificationManager.shared.syncStoredToken(userUuid: user.userUuid)
    }
}

private struct AppCurrentUserSnapshot: Equatable {
    let userUuid: String?
    let uid: String?
    let provider: String?
    let email: String?
    let nickname: String?
    let role: String?
    let isAlerted: Bool?
    let fcmToken: String?
    let alertKeywordList: [String]?
    let recommendList: [Int]?

    init(_ user: User?) {
        userUuid = user?.userUuid
        uid = user?.uid
        provider = user?.provider
        email = user?.email
        nickname = user?.nickname
        role = user?.role
        isAlerted = user?.isAlerted
        fcmToken = user?.fcmToken
        alertKeywordList = user?.alertKeywordList
        recommendList = user?.recommendList
    }
}
