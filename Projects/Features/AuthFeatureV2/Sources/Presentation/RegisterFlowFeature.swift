import ComposableArchitecture
import Domain
import DSKit
import Foundation

@Reducer
public struct RegisterFlowFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentStep: RegisterRoute = .nickname
        public var isForward = true
        public var nickname = ""
        public var validationState: NicknameValidationState = .none
        /// 추천 닉네임을 받는 중. 응답이 오면 닉네임이 바뀌므로 그동안 "다음"을 막는다.
        public var isRecommendingNickname = false
        public var recommendList: [Recommend] = []
        /// 카테고리 목록을 받지 못했다. 카테고리 단계에 "다시 시도"를 보여 준다.
        public var isRecommendListLoadFailed = false
        public var selectedCategories: [Int] = []
        public var keywords: [String] = []
        public var keywordInput = ""
        /// 키워드를 5개 넘게 더하려고 할 때 띄우는 제한 알림
        public var isKeywordLimitAlertPresented = false
        /// 키워드 단계의 "많이 등록한 키워드". 받지 못했거나 비어 있으면 화면에서 숨긴다.
        public var popularKeywords: [String] = []
        /// 인기 키워드는 가입 흐름에 들어올 때 한 번만 받는다. 빈 배열이어도 다시 받지 않는다.
        public var hasRequestedPopularKeywords = false
        /// 가입에 성공한 사용자. 완료 화면의 "시작하기"를 누를 때 `completed`로 넘긴다.
        public var signedUpUser: User?
        public var isSubmitting = false
        /// 건너뛰기로 가입 중. 키워드 없이 요청하고, 성공하면 화면의 키워드도 비운다. 실패하면 키워드를 그대로 둔다.
        public var isSkippingKeywords = false
        public var errorMessage: String?
        /// 가입할 소셜 로그인 제공자. 로그인 결과가 가입 필요(PENDING)일 때 받는다.
        public let provider: Provider

        public init(provider: Provider) {
            self.provider = provider
        }
    }

    public enum Action {
        case onAppear
        case recommendListResponse(Result<[Recommend], Error>)
        case retryRecommendListTapped
        case backTapped
        case skipTapped
        case nicknameChanged(String)
        case recommendNicknameTapped
        case nicknameRecommendationResponse(Result<String, Error>)
        case validateNicknameTapped
        /// `nickname`은 확인을 요청한 닉네임이다. 그 사이 입력이 바뀌었으면 결과를 버린다.
        case validateNicknameResponse(nickname: String, Result<Bool, Error>)
        case nextFromNicknameTapped
        case categoryToggled(Int)
        case nextFromCategoryTapped
        case keywordInputChanged(String)
        case keywordAdded(String)
        case keywordRemoved(Int)
        case keywordLimitAlertDismissed
        case popularKeywordsResponse(Result<[String], Error>)
        case popularKeywordTapped(String)
        case completeRegistrationTapped
        case completeRegistrationResponse(Result<User, Error>)
        case startTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case completed(User)
            /// 가입을 끝낼 수 없다(가입 단계 만료, 탈퇴 계정). 안내와 함께 소셜 로그인부터 다시 해야 한다.
            case loginRequired(errorMessage: String)
        }
    }

    @Dependency(\.authFeatureClient) private var authFeatureClient: AuthFeatureClient

    private enum CancelID {
        case nicknameRecommendation
    }

    /// 가입할 때 등록할 수 있는 키워드 최대 개수
    public static let maxKeywordCount = 5

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                var effects: [Effect<Action>] = []
                // 닉네임을 아직 정하지 않았으면 추천 닉네임을 미리 채운다.
                if state.nickname.isEmpty {
                    state.isRecommendingNickname = true
                    effects.append(recommendNickname())
                }
                if state.recommendList.isEmpty {
                    state.isRecommendListLoadFailed = false
                    effects.append(fetchRecommendList())
                }
                if !state.hasRequestedPopularKeywords {
                    state.hasRequestedPopularKeywords = true
                    effects.append(.run { [authFeatureClient] send in
                        await send(.popularKeywordsResponse(Result {
                            try await authFeatureClient.getPopularKeywords()
                        }))
                    })
                }
                return .merge(effects)

            case .recommendListResponse(.success(let recommendList)):
                state.recommendList = recommendList
                // 빈 목록이면 고를 칩이 없어 다음으로 갈 수 없다. 실패처럼 다시 시도를 보여 준다.
                state.isRecommendListLoadFailed = recommendList.isEmpty
                return .none

            case .recommendListResponse(.failure(let error)):
                if (error as? AuthError) == .signupSessionExpired {
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired)))
                }
                // 닉네임 화면이 아니라 목록이 필요한 카테고리 단계에서 안내하고 다시 받게 한다.
                state.isRecommendListLoadFailed = true
                return .none

            case .retryRecommendListTapped:
                state.isRecommendListLoadFailed = false
                return fetchRecommendList()

            case .backTapped:
                // 실패 문구는 닉네임·키워드 단계가 함께 쓰므로 단계를 옮기면 지운다.
                if state.currentStep != .nickname, state.currentStep != .complete {
                    state.errorMessage = nil
                }
                switch state.currentStep {
                case .keyword:
                    state.currentStep = .category
                    state.isForward = false
                case .category:
                    state.currentStep = .nickname
                    state.isForward = false
                case .nickname, .complete:
                    // 가입을 마친 뒤에는 앞 단계로 돌아가지 않는다.
                    break
                }
                return .none

            case .skipTapped:
                switch state.currentStep {
                case .keyword:
                    // 건너뛰면 넣어 둔 키워드도 등록하지 않는다. 알림이 꺼진 채 가입한다.
                    // 화면의 키워드는 가입이 성공한 뒤에 비운다. 실패하면 다시 고를 수 있게 둔다.
                    guard !state.isSubmitting else { return .none }
                    state.isSkippingKeywords = true
                    return signup(&state, keywords: [])
                case .nickname, .category, .complete:
                    // 닉네임·카테고리 단계는 건너뛸 수 없다. 카테고리는 1개 이상 골라야 다음으로 간다.
                    return .none
                }

            case .nicknameChanged(let nickname):
                // 입력칸이 같은 값을 다시 보내도 확인한 상태를 지우지 않는다.
                guard nickname != state.nickname else { return .none }
                state.nickname = nickname
                state.validationState = Self.localValidationState(for: nickname)
                state.errorMessage = nil
                // 직접 입력하면 늦게 도착한 추천 닉네임으로 덮어쓰지 않는다.
                state.isRecommendingNickname = false
                return .cancel(id: CancelID.nicknameRecommendation)

            case .recommendNicknameTapped:
                guard !state.isSubmitting else { return .none }
                state.isRecommendingNickname = true
                return recommendNickname()

            case .nicknameRecommendationResponse(.success(let nickname)):
                // 서버가 중복을 확인한 닉네임이라 바로 쓸 수 있다고 보여 준다. 가입할 때 서버가 다시 확인한다.
                state.isRecommendingNickname = false
                state.nickname = nickname
                state.validationState = .success
                state.errorMessage = nil
                return .none

            case .nicknameRecommendationResponse(.failure(let error)):
                state.isRecommendingNickname = false
                if (error as? AuthError) == .signupSessionExpired {
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired)))
                }
                // 추천을 받지 못하면 직접 입력하게 두고 따로 안내하지 않는다.
                return .none

            case .validateNicknameTapped:
                // 확인 중에 다시 누르면 요청을 또 보내지 않는다.
                guard !state.isSubmitting else { return .none }
                // 입력할 때와 같은 규칙으로 먼저 거른다. 빈 칸은 너무 짧은 닉네임으로 본다.
                let localState = Self.localValidationState(for: state.nickname)
                guard localState == .none, !state.nickname.isEmpty else {
                    state.validationState = localState == .none ? .tooShort : localState
                    return .none
                }
                state.isSubmitting = true
                state.isRecommendingNickname = false
                state.validationState = .checking
                state.errorMessage = nil
                let nickname = state.nickname
                return .merge(
                    // 확인하는 동안 늦게 도착한 추천 닉네임이 입력칸을 덮어쓰지 않게 한다.
                    .cancel(id: CancelID.nicknameRecommendation),
                    .run { [authFeatureClient] send in
                        await send(.validateNicknameResponse(nickname: nickname, Result {
                            try await authFeatureClient.checkNickname(nickname)
                        }))
                    }
                )

            case .validateNicknameResponse(let nickname, _) where nickname != state.nickname:
                // 확인을 누른 뒤 닉네임을 고쳤다. 고친 닉네임은 아직 확인하지 않은 상태로 둔다.
                state.isSubmitting = false
                return .none

            case .validateNicknameResponse(_, .success(let isDuplicated)):
                state.isSubmitting = false
                state.validationState = isDuplicated ? .duplicate : .success
                return .none

            case .validateNicknameResponse(_, .failure(let error)):
                state.isSubmitting = false
                state.validationState = .none
                if (error as? AuthError) == .signupSessionExpired {
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired)))
                }
                state.errorMessage = AuthErrorMessage.nicknameCheckFailed
                return .none

            case .nextFromNicknameTapped:
                guard state.validationState == .success, !state.isRecommendingNickname else { return .none }
                state.errorMessage = nil
                state.currentStep = .category
                state.isForward = true
                return .none

            case .categoryToggled(let id):
                if let index = state.selectedCategories.firstIndex(of: id) {
                    state.selectedCategories.remove(at: index)
                } else {
                    state.selectedCategories.append(id)
                }
                return .none

            case .nextFromCategoryTapped:
                guard !state.selectedCategories.isEmpty else { return .none }
                state.currentStep = .keyword
                state.isForward = true
                return .none

            case .keywordInputChanged(let value):
                state.keywordInput = value
                return .none

            case .keywordAdded(let keyword):
                guard Self.appendKeyword(keyword, to: &state) else { return .none }
                state.keywordInput = ""
                return .none

            case .popularKeywordTapped(let keyword):
                // 직접 추가와 같은 규칙(5개, 중복)을 따르고, 입력 중인 글자는 그대로 둔다.
                _ = Self.appendKeyword(keyword, to: &state)
                return .none

            case .keywordLimitAlertDismissed:
                state.isKeywordLimitAlertPresented = false
                return .none

            case .popularKeywordsResponse(.success(let keywords)):
                // 서버가 같은 키워드를 여러 번 주어도 칩은 한 번만 보여 준다 (칩 목록이 키워드를 id로 쓴다).
                var seen = Set<String>()
                state.popularKeywords = keywords.filter { seen.insert($0).inserted }
                return .none

            case .popularKeywordsResponse(.failure(let error)):
                if (error as? AuthError) == .signupSessionExpired {
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired)))
                }
                // 인기 키워드를 받지 못하면 영역을 숨기고 따로 안내하지 않는다.
                state.popularKeywords = []
                return .none

            case .keywordRemoved(let index):
                guard state.keywords.indices.contains(index) else { return .none }
                state.keywords.remove(at: index)
                return .none

            case .completeRegistrationTapped:
                guard !state.isSubmitting else { return .none }
                state.isSkippingKeywords = false
                return signup(&state, keywords: state.keywords)

            case .completeRegistrationResponse(.success(let user)):
                // 바로 메인으로 가지 않고 완료 화면을 보여 준다. 메인 이동은 완료 화면 버튼에서 한다.
                state.isSubmitting = false
                if state.isSkippingKeywords {
                    state.keywords = []
                    state.keywordInput = ""
                    state.isSkippingKeywords = false
                }
                state.signedUpUser = user
                state.currentStep = .complete
                state.isForward = true
                return .none

            case .startTapped:
                // 알림 권한은 앱을 시작할 때 묻는다. 여기서는 따로 묻지 않고 바로 메인으로 간다 (D-6).
                guard let user = state.signedUpUser else { return .none }
                return .send(.delegate(.completed(user)))

            case .completeRegistrationResponse(.failure(let error)):
                state.isSubmitting = false
                state.isSkippingKeywords = false
                switch error as? AuthError {
                case .signupSessionExpired:
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired)))
                case .inactiveAccount:
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signup(for: AuthError.inactiveAccount))))
                case .duplicateNickname:
                    // 닉네임 화면으로 돌아가 다른 닉네임을 입력하게 한다.
                    // 중복 안내는 닉네임 확인 문구가 보여 주므로 같은 뜻의 빨간 문구를 더하지 않는다.
                    state.currentStep = .nickname
                    state.isForward = false
                    state.validationState = .duplicate
                    return .none
                default:
                    break
                }
                state.errorMessage = AuthErrorMessage.signup(for: error)
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

public enum RegisterRoute: Int, CaseIterable, Hashable, Sendable {
    case nickname = 0
    case category
    case keyword
    /// 가입 완료 화면. 진행 막대와 `n/3`에는 세지 않는다.
    case complete

    var index: Int { rawValue }

    /// 진행 막대와 `n/3`에 세는 가입 단계
    static let inputSteps: [RegisterRoute] = [.nickname, .category, .keyword]
}

private extension RegisterFlowFeature {
    /// 가입을 요청한다. 키워드가 없으면 알림을 끈 채 가입한다.
    func signup(_ state: inout State, keywords: [String]) -> Effect<Action> {
        state.isSubmitting = true
        state.errorMessage = nil

        let provider = state.provider
        let request = SignupRequest(
            nickname: state.nickname,
            isAlerted: !keywords.isEmpty,
            fcmToken: nil,
            alertKeywordList: keywords,
            recommendList: state.selectedCategories
        )

        return .run { [authFeatureClient] send in
            await send(.completeRegistrationResponse(Result {
                try await authFeatureClient.signup(provider, request)
            }))
        }
    }

    func fetchRecommendList() -> Effect<Action> {
        .run { [authFeatureClient] send in
            await send(.recommendListResponse(Result {
                try await authFeatureClient.getRecommendList()
            }))
        }
    }

    func recommendNickname() -> Effect<Action> {
        .run { [authFeatureClient] send in
            await send(.nicknameRecommendationResponse(Result {
                try await authFeatureClient.recommendNickname()
            }))
        }
        .cancellable(id: CancelID.nicknameRecommendation, cancelInFlight: true)
    }

    /// 키워드를 내 키워드 끝에 더한다. 비었거나 같은 키워드가 있으면 더하지 않는다.
    /// 이미 5개면 더하지 않고 제한 알림을 띄운다.
    static func appendKeyword(_ keyword: String, to state: inout State) -> Bool {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        guard state.keywords.count < maxKeywordCount else {
            state.isKeywordLimitAlertPresented = true
            return false
        }
        guard !state.keywords.contains(trimmed) else { return false }
        state.keywords.append(trimmed)
        return true
    }

    static func localValidationState(for nickname: String) -> NicknameValidationState {
        if nickname.isEmpty {
            return .none
        } else if nickname.contains(" ") {
            return .invalidSpace
        } else if nickname.count <= 2 {
            return .tooShort
        } else {
            return .none
        }
    }
}
