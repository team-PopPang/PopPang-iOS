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
        var initialUser: User?

        public init(user: User?) {
            self.initialUser = user
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
                state.errorMessage = error.localizedDescription
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
                state.errorMessage = error.localizedDescription
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

                var user = state.initialUser ?? User(
                    userUuid: UUID().uuidString,
                    uid: UUID().uuidString,
                    provider: "KAKAO",
                    email: nil,
                    nickname: nil,
                    role: "USER",
                    isAlerted: false,
                    fcmToken: nil,
                    alertKeywordList: nil,
                    recommendList: nil
                )
                user.nickname = state.nickname
                user.recommendList = state.selectedCategories
                user.alertKeywordList = state.keywords
                user.isAlerted = !state.keywords.isEmpty
                let registrationUser = user

                return .run { [authFeatureClient, registrationUser] send in
                    do {
                        let registeredUser: User
                        switch registrationUser.provider.uppercased() {
                        case "APPLE":
                            registeredUser = try await authFeatureClient.appleRegister(registrationUser)
                        case "GOOGLE":
                            registeredUser = try await authFeatureClient.googleRegister(registrationUser)
                        default:
                            registeredUser = try await authFeatureClient.kakaoRegister(registrationUser)
                        }
                        await send(.completeRegistrationResponse(.success(registeredUser)))
                    } catch {
                        await send(.completeRegistrationResponse(.failure(error)))
                    }
                }

            case .completeRegistrationResponse(.success(let user)):
                state.isSubmitting = false
                return .send(.delegate(.completed(user)))

            case .completeRegistrationResponse(.failure(let error)):
                state.isSubmitting = false
                state.errorMessage = error.localizedDescription
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
