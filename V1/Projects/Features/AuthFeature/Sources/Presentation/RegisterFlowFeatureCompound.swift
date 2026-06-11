import Compound
import Domain
import DSKit
import Foundation

@Compound
final class RegisterFlowFeatureCompound {
    enum Action {
        case onAppear
        case setStep(RegisterRoute, isForward: Bool)
        case nicknameChanged(String)
        case validateNickname(String)
        case categoryToggled(Int)
        case keywordAdded(String)
        case keywordRemoved(Int)
        case completeRegistration(nickname: String, keywords: [String], selectedCategories: [Int])
        case setErrorMessage(String?)
    }

    enum Reaction {
        case setStep(RegisterRoute, Bool)
        case setNickname(String)
        case setValidationState(NicknameValidationState)
        case setRecommendList([Recommend])
        case setSelectedCategories([Int])
        case setKeywords([String])
        case setSubmitting(Bool)
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        var currentStep: RegisterRoute = .nickname
        var isForward = true
        var nickname = ""
        var validationState: NicknameValidationState = .none
        var recommendList: [Recommend]
        var selectedCategories: [Int] = []
        var keywords: [String] = []
        var isSubmitting = false
        var errorMessage: String?
    }

    var state: State

    private let initialUser: User?
    private let onComplete: @MainActor (User) -> Void

    @Dependency private var appleAuthUsecase: AppleAuthUsecaseProtocol
    @Dependency private var googleAuthUsecase: GoogleAuthUsecaseProtocol
    @Dependency private var kakaoAuthUsecase: KakaoAuthUsecaseProtocol
    @Dependency private var userUsecase: UserUsecaseProtocol

    init(
        user: User?,
        onComplete: @escaping @MainActor (User) -> Void = { _ in }
    ) {
        self.initialUser = user
        self.onComplete = onComplete
        self.state = State(recommendList: [])
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            return loadRecommendList()

        case .setStep(let route, let isForward):
            return .just(.setStep(route, isForward))

        case .nicknameChanged(let nickname):
            let validationState: NicknameValidationState
            if nickname.isEmpty {
                validationState = .none
            } else if nickname.contains(" ") {
                validationState = .invalidSpace
            } else if nickname.count <= 2 {
                validationState = .tooShort
            } else {
                validationState = .none
            }

            return .merge(
                .just(.setNickname(nickname)),
                .just(.setValidationState(validationState))
            )

        case .validateNickname(let nickname):
            guard !nickname.contains(" ") else {
                return .just(.setValidationState(.invalidSpace))
            }
            guard nickname.count > 2 else {
                return .just(.setValidationState(.tooShort))
            }

            return .concat(
                .just(.setSubmitting(true)),
                .just(.setValidationState(.checking)),
                .just(.setErrorMessage(nil)),
                .run { [userUsecase] send in
                    do {
                        let isDuplicated = try await userUsecase.checkNickname(nickname: nickname)
                        await send(.setValidationState(isDuplicated ? .duplicate : .success))
                    } catch {
                        await send(.setValidationState(.none))
                        await send(.setErrorMessage(error.localizedDescription))
                    }
                    await send(.setSubmitting(false))
                }
            )

        case .categoryToggled(let id):
            var selectedCategories = state.selectedCategories
            if let index = selectedCategories.firstIndex(of: id) {
                selectedCategories.remove(at: index)
            } else {
                selectedCategories.append(id)
            }
            return .just(.setSelectedCategories(selectedCategories))

        case .keywordAdded(let text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return Self.emptyReactionStream() }
            guard state.keywords.count < 5 else { return Self.emptyReactionStream() }
            guard !state.keywords.contains(trimmed) else { return Self.emptyReactionStream() }

            return .just(.setKeywords(state.keywords + [trimmed]))

        case .keywordRemoved(let index):
            guard state.keywords.indices.contains(index) else { return Self.emptyReactionStream() }
            var keywords = state.keywords
            keywords.remove(at: index)
            return .just(.setKeywords(keywords))

        case .completeRegistration(let nickname, let keywords, let selectedCategories):
            return .concat(
                .just(.setSubmitting(true)),
                .just(.setErrorMessage(nil)),
                .run { [initialUser, appleAuthUsecase, googleAuthUsecase, kakaoAuthUsecase, onComplete] send in
                    var user = initialUser ?? User(
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
                    user.nickname = nickname
                    user.recommendList = selectedCategories
                    user.alertKeywordList = keywords
                    user.isAlerted = !keywords.isEmpty

                    do {
                        let registeredUser: User
                        switch user.provider.uppercased() {
                        case "APPLE":
                            registeredUser = try await appleAuthUsecase.appleRegister(user: user)
                        case "GOOGLE":
                            registeredUser = try await googleAuthUsecase.googleRegister(user: user)
                        default:
                            registeredUser = try await kakaoAuthUsecase.kakaoRegister(user: user)
                        }
                        await send(.setSubmitting(false))
                        await onComplete(registeredUser)
                    } catch {
                        await send(.setSubmitting(false))
                        await send(.setErrorMessage(error.localizedDescription))
                    }
                }
            )

        case .setErrorMessage(let errorMessage):
            return .just(.setErrorMessage(errorMessage))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setStep(let route, let isForward):
            newState.currentStep = route
            newState.isForward = isForward
        case .setNickname(let nickname):
            newState.nickname = nickname
        case .setValidationState(let validationState):
            newState.validationState = validationState
        case .setRecommendList(let recommendList):
            newState.recommendList = recommendList
        case .setSelectedCategories(let selectedCategories):
            newState.selectedCategories = selectedCategories
        case .setKeywords(let keywords):
            newState.keywords = keywords
        case .setSubmitting(let isSubmitting):
            newState.isSubmitting = isSubmitting
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        }

        return newState
    }

    private static func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
}

private extension RegisterFlowFeatureCompound {
    func loadRecommendList() -> AsyncStream<Reaction> {
        let userUsecase = userUsecase

        return .concat(
            .just(.setErrorMessage(nil)),
            .run { send in
                do {
                    let recommendList = try await userUsecase.getRecommandList()
                    await send(.setRecommendList(recommendList))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }
            }
        )
    }
}

enum RegisterRoute: Int, CaseIterable, Hashable, Sendable {
    case nickname = 0
    case category
    case keyword

    var index: Int { rawValue }
}
