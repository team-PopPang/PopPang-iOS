import ComposableArchitecture
import AuthFeature
import Core
import Domain
import OnboardingFeature
import MainTabFeature

/// 앱 최상위에서 표시할 화면
enum AppRootDestination: Equatable, Sendable {
    case launch     /// 시작
    case onboarding /// 온보딩
    case auth       /// 로그인
    case register   /// 회원정보 입력 화면
    case main       /// 로그인 완료 후 메인 화면
}

/// 앱 실행 시 저장된 세션을 확인한 결과를 나타낸다
enum AppLaunchResolution {
    /// 사용자 정보 없이 특정 화면으로 이동
    case destination(AppRootDestination)
    
    /// 인증과 회원가입이 모두 완료된 사용자
    case authenticated(User)
    
    /// 인증은 완료됐지만 추가 회원정보 입력이 필요한 사용자
    case registrationRequired(User)
}

extension AppFeature.OnboardingPath.State: Equatable {}

@Reducer
struct AppFeature {
    @ObservableState
    struct State: Equatable {
        /// 여러 하위 Feature가 공유하는 사용자 세션
        @Shared var session: UserSession
        
        /// 현재 앱 루트에 표시할 화면
        var destination: AppRootDestination = .launch
        
        /// 기본 로그인 화면의 상태
        var auth = AuthFeature.State()
        
        /// 추가 회원정보 입력이 필요할 때 생성되는 상태
        var registerFlow: RegisterFlowFeature.State?
        
        /// 온보딩 화면의 상태
        var onboarding = OnboardingFeature.State()
        
        /// /// 온보딩 내부 NavigationStack 경로
        var onboardingPath = StackState<OnboardingPath.State>()
        
        /// 메인 화면에 진입했을 때 생성되는 상태
        var mainTab: MainTabFeature.State?

        /// 초기 사용자 세션을 전달받아 공유 상태로 생성
        init(session: UserSession = .init()) {
            self._session = Shared(value: session)
        }
    }

    enum Action {
        /// 앱 실행 시 저장된 세션과 초기 화면을 확인
        case launchTask
        
        /// 앱 실행 상태 확인이 완료됐을 때 전달
        case launchResolved(UserSession, AppRootDestination)
        
        /// Actions
        case auth(AuthFeature.Action)
        case registerFlow(RegisterFlowFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case onboardingPath(StackActionOf<OnboardingPath>)
        
        /// 소셜 인증이 완료됐을 때 사용자 정보를 전달
        case authCompleted(User)
        
        /// 추가 회원정보 등록이 완료됐을 때 사용자 정보를 전달
        case registerCompleted(User)
        
        /// 저장된 세션 제거가 완료됐음
        case logoutFinished
        
        /// 메인 탭 Feature의 액션
        case mainTab(MainTabFeature.Action)
    }

    /// 온보딩 화면에서 이동할 수 있는 경로
    @Reducer
    enum OnboardingPath {
        case auth(AuthFeature)
    }

    /// 사용자 세션을 불러오고 저장하거나 제거하는 TCA 의존성
    @Dependency(\.localSessionClient) private var localSessionClient: LocalSessionClient
    
    /// 온보딩 완료 여부 등의 로컬 값을 동기적으로 관리
    private let sessionStorage: LocalSessionStorage
    
    /// 저장된 정보와 현재 세션을 바탕으로 초기 화면을 결정
    private let launchStateResolver: AppLaunchStateResolver

    init(
        sessionStorage: LocalSessionStorage,
        launchStateResolver: AppLaunchStateResolver
    ) {
        self.sessionStorage = sessionStorage
        self.launchStateResolver = launchStateResolver
    }

    var body: some ReducerOf<Self> {
        // 기본 로그인 화면을 AppFeature에 연결
        Scope(state: \.auth, action: \.auth) {
            AuthFeature()
        }

        // 추가 회원정보 입력 상태가 존재할 때만 RegisterFlowFeature를 실행
        EmptyReducer()
            .ifLet(\.registerFlow, action: \.registerFlow) {
                RegisterFlowFeature()
            }

        // 온보딩 화면을 AppFeature에 연결
        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Reduce { state, action in
            switch action {
            case .launchTask:
                // 초기 화면 확인이 중복 실행되지 않도록 launch 상태에서만 처리
                guard state.destination == .launch else { return .none }
                return resolveLaunch()

            case .launchResolved(let session, let destination):
                // 확인한 세션과 목적지를 앱 루트 상태에 반영
                applyLaunchState(
                    session: session,
                    destination: destination,
                    state: &state
                )
                return .none

            case .onboarding(.delegate(.authRequested)):
                // 사용자가 온보딩에서 로그인을 선택했으므로 온보딩 완료 여부를 저장
                sessionStorage.setOnboardingCompleted(true)
                
                // 로그인 화면이 중복으로 push되지 않도록 경로가 비어 있을 때만 추가
                if state.onboardingPath.isEmpty {
                    state.onboardingPath.append(.auth(.init()))
                }
                return .none

            case let .auth(.delegate(.authenticated(user))),
                 let .onboardingPath(.element(_, .auth(.delegate(.authenticated(user))))):
                // 루트 로그인과 온보딩 내부 로그인의 성공 결과를 하나의 공통 액션으로 통합
                return .send(.authCompleted(user))

            case let .registerFlow(.delegate(.completed(user))):
                // 추가 회원정보 등록 완료 결과를 공통 액션으로 전달
                return .send(.registerCompleted(user))

            case .authCompleted(let user),
                    .registerCompleted(let user):
                // 인증 또는 회원가입 완료 사용자 정보를 앱 상태에 반영
                applyAuthenticatedUser(user, state: &state)
                
                // 최신 사용자 세션을 로컬에 저장
                return .run { _ in
                    await localSessionClient.saveUser(user)
                }

            case .mainTab(.delegate(.logout)):
                // 로그아웃 요청 즉시 온보딩 화면으로 전환
                state.destination = .onboarding
                
                // 저장된 사용자 세션을 제거한 뒤 후속 액션을 전달
                return .run { send in
                     await localSessionClient.clear()
                     await send(.logoutFinished)
                }

            case .logoutFinished:
                // 로그인과 회원가입 관련 상태를 초기화
                state.auth = .init()
                state.registerFlow = nil
                
                // 온보딩 화면과 NavigationStack 상태를 초기화
                state.onboarding = .init()
                state.onboardingPath = StackState()
                
                // 메인 화면 상태를 제거
                state.mainTab = nil
                
                // 모든 하위 Feature가 공유하는 사용자 세션을 초기화
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
        // 온보딩 NavigationStack에 포함된 각 화면의 Reducer를 연결
        .forEach(\.onboardingPath, action: \.onboardingPath)
        
        // 메인 탭 상태가 존재할 때만 MainTabFeature를 실행
        .ifLet(\.mainTab, action: \.mainTab) {
            MainTabFeature()
        }
    }
}

private extension AppFeature {
    /// 저장된 세션을 불러오고 앱 시작 화면을 결정
    func resolveLaunch() -> Effect<Action> {
        let sessionStorage = sessionStorage
        let launchStateResolver = launchStateResolver

        return .run { send in
            // 온보딩 완료 여부 등 동기 저장 정보 확인
            let latestSnapshot = sessionStorage.loadSnapshot()
            
            // 저장된 사용자 세션을 비동기로 불러옴
            let session = await localSessionClient.load()
            
            // 저장 정보와 세션을 조합해 앱 최초 화면을 결정
            let destination = launchStateResolver.resolve(
                snapshot: latestSnapshot,
                session: session
            )

            await send(.launchResolved(session, destination))
        }
    }
    
    /// 앱 실행 시 불러온 세션과 목적지를 최상위 상태에 반영
    func applyLaunchState(
        session: UserSession,
        destination: AppRootDestination,
        state: inout State
    ) {
        // 공유 세션을 최신 값으로 교체
        state.$session.withLock { $0 = session }
        state.destination = destination
        
        // 이전 인증 및 화면 전환 상태를 초기화
        state.auth = .init()
        state.registerFlow = nil
        state.onboarding = .init()
        state.onboardingPath = StackState()

        if destination == .main, session.user != nil {
            // 인증과 회원정보 등록이 완료됐다면 메인 탭 상태를 생성
            state.mainTab = state.mainTab ?? .init(session: state.$session)
        } else if destination == .register, let user = session.user {
            // 인증은 완료됐지만 닉네임 등 추가 정보가 필요하면 회원정보 입력 흐름을 생성
            state.registerFlow = .init(user: user)
            state.mainTab = nil
        } else {
            // 그 외 화면에서는 메인 탭 상태를 유지하지 않는다
            state.mainTab = nil
        }
    }

    /// 인증 또는 회원가입이 완료된 사용자를 앱 상태에 반영
    func applyAuthenticatedUser(_ user: User, state: inout State) {
        
        // 온보딩 완료 여부와 푸시 토큰 동기화를 처리
        configureAuthenticatedSession(user)
        
        // 모든 하위 Feature가 공유하는 세션에 사용자를 저장
        state.$session.withLock { $0.user = user }
        
        // 인증 관련 임시 상태를 초기화
        state.auth = .init()
        state.onboarding = .init()
        state.onboardingPath = StackState()

        if user.nickname == nil {
            // 닉네임이 없으면 추가 회원정보 입력 화면으로 이동
            state.mainTab = nil
            state.registerFlow = .init(user: user)
            state.destination = .register
        } else {
            // 필요한 회원정보가 모두 있으면 메인 화면으로 이동
            state.registerFlow = nil
            state.mainTab = state.mainTab ?? .init(session: state.$session)
            state.destination = .main
        }
    }

    /// 인증 완료 후 필요한 앱 외부 상태를 설정
    func configureAuthenticatedSession(_ user: User) {
        // 인증까지 완료된 사용자는 온보딩을 완료한 것으로 저장
        sessionStorage.setOnboardingCompleted(true)
        
        // 로그인 전 저장됐던 푸시 토큰을 현재 사용자 계정과 동기화
        AppNotificationManager.shared.syncStoredToken(userUuid: user.userUuid)
    }
}
