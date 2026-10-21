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
        public var recommendList: [Recommend] = []
        public var selectedCategories: [Int] = []
        public var keywords: [String] = []
        public var keywordInput = ""
        public var isSubmitting = false
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
        case backTapped
        case skipTapped
        case nicknameChanged(String)
        case validateNicknameTapped
        case validateNicknameResponse(Result<Bool, Error>)
        case nextFromNicknameTapped
        case categoryToggled(Int)
        case nextFromCategoryTapped
        case keywordInputChanged(String)
        case keywordAdded(String)
        case keywordRemoved(Int)
        case completeRegistrationTapped
        case completeRegistrationResponse(Result<User, Error>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case completed(User)
            /// 가입을 끝낼 수 없다(가입 단계 만료, 탈퇴 계정). 안내와 함께 소셜 로그인부터 다시 해야 한다.
            case loginRequired(errorMessage: String)
        }
    }

    @Dependency(\.authFeatureClient) private var authFeatureClient: AuthFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.recommendList.isEmpty else { return .none }
                state.errorMessage = nil
                return .run { [authFeatureClient] send in
                    do {
                        let recommendList = try await authFeatureClient.getRecommendList()
                        await send(.recommendListResponse(.success(recommendList)))
                    } catch {
                        await send(.recommendListResponse(.failure(error)))
                    }
                }

            case .recommendListResponse(.success(let recommendList)):
                state.recommendList = recommendList
                return .none

            case .recommendListResponse(.failure(let error)):
                if (error as? AuthError) == .signupSessionExpired {
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired)))
                }
                state.errorMessage = AuthErrorMessage.recommendListLoadFailed
                return .none

            case .backTapped:
                switch state.currentStep {
                case .keyword:
                    state.currentStep = .category
                    state.isForward = false
                case .category:
                    state.currentStep = .nickname
                    state.isForward = false
                case .nickname:
                    break
                }
                return .none

            case .skipTapped:
                switch state.currentStep {
                case .category:
                    state.currentStep = .keyword
                    state.isForward = true
                    return .none
                case .keyword:
                    return .send(.completeRegistrationTapped)
                case .nickname:
                    return .none
                }

            case .nicknameChanged(let nickname):
                state.nickname = nickname
                state.validationState = Self.localValidationState(for: nickname)
                if state.validationState != .checking {
                    state.errorMessage = nil
                }
                return .none

            case .validateNicknameTapped:
                guard !state.nickname.contains(" ") else {
                    state.validationState = .invalidSpace
                    return .none
                }
                guard state.nickname.count > 2 else {
                    state.validationState = .tooShort
                    return .none
                }
                state.isSubmitting = true
                state.validationState = .checking
                state.errorMessage = nil
                let nickname = state.nickname
                return .run { [authFeatureClient] send in
                    do {
                        let isDuplicated = try await authFeatureClient.checkNickname(nickname)
                        await send(.validateNicknameResponse(.success(isDuplicated)))
                    } catch {
                        await send(.validateNicknameResponse(.failure(error)))
                    }
                }

            case .validateNicknameResponse(.success(let isDuplicated)):
                state.isSubmitting = false
                state.validationState = isDuplicated ? .duplicate : .success
                return .none

            case .validateNicknameResponse(.failure(let error)):
                state.isSubmitting = false
                state.validationState = .none
                if (error as? AuthError) == .signupSessionExpired {
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired)))
                }
                state.errorMessage = AuthErrorMessage.nicknameCheckFailed
                return .none

            case .nextFromNicknameTapped:
                guard state.validationState == .success else { return .none }
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
                let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return .none }
                guard state.keywords.count < 5 else { return .none }
                guard !state.keywords.contains(trimmed) else { return .none }
                state.keywords.append(trimmed)
                state.keywordInput = ""
                return .none

            case .keywordRemoved(let index):
                guard state.keywords.indices.contains(index) else { return .none }
                state.keywords.remove(at: index)
                return .none

            case .completeRegistrationTapped:
                guard !state.isSubmitting else { return .none }
                state.isSubmitting = true
                state.errorMessage = nil

                let provider = state.provider
                let request = SignupRequest(
                    nickname: state.nickname,
                    isAlerted: !state.keywords.isEmpty,
                    fcmToken: nil,
                    alertKeywordList: state.keywords,
                    recommendList: state.selectedCategories
                )

                return .run { [authFeatureClient] send in
                    await send(.completeRegistrationResponse(Result {
                        try await authFeatureClient.signup(provider, request)
                    }))
                }

            case .completeRegistrationResponse(.success(let user)):
                state.isSubmitting = false
                return .send(.delegate(.completed(user)))

            case .completeRegistrationResponse(.failure(let error)):
                state.isSubmitting = false
                switch error as? AuthError {
                case .signupSessionExpired:
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signupSessionExpired)))
                case .inactiveAccount:
                    return .send(.delegate(.loginRequired(errorMessage: AuthErrorMessage.signup(for: AuthError.inactiveAccount))))
                case .duplicateNickname:
                    // 닉네임 화면으로 돌아가 다른 닉네임을 입력하게 한다.
                    state.currentStep = .nickname
                    state.isForward = false
                    state.validationState = .duplicate
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

    var index: Int { rawValue }
}

private extension RegisterFlowFeature {
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
