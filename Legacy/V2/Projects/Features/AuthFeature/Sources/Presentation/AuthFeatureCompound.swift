@preconcurrency import AuthenticationServices
import Compound
import Domain
import Foundation

@Compound
final class AuthFeatureCompound {
    struct AppleAuthorization: @unchecked Sendable {
        let value: ASAuthorization

        init(_ value: ASAuthorization) {
            self.value = value
        }
    }

    enum Action {
        case kakaoLogin
        case googleLogin
        case appleLogin(AppleAuthorization)
    }

    enum Reaction {
        case setSubmitting(Bool)
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        var isSubmitting = false
        var errorMessage: String?
    }

    var state = State()

    @Dependency private var kakaoAuthUsecase: KakaoAuthUsecaseProtocol
    @Dependency private var googleAuthUsecase: GoogleAuthUsecaseProtocol
    @Dependency private var appleAuthUsecase: AppleAuthUsecaseProtocol

    private let onLoginSuccess: @MainActor (User) -> Void

    init(
        onLoginSuccess: @escaping @MainActor (User) -> Void = { _ in }
    ) {
        self.onLoginSuccess = onLoginSuccess
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        let kakaoAuthUsecase = kakaoAuthUsecase
        let googleAuthUsecase = googleAuthUsecase
        let appleAuthUsecase = appleAuthUsecase

        return .concat(
            .just(.setSubmitting(true)),
            .just(.setErrorMessage(nil)),
            .run { [kakaoAuthUsecase, googleAuthUsecase, appleAuthUsecase, onLoginSuccess] send in
                do {
                    let user: User
                    switch action {
                    case .kakaoLogin:
                        user = try await kakaoAuthUsecase.kakaoLogin()
                    case .googleLogin:
                        user = try await googleAuthUsecase.googleLogin()
                    case .appleLogin(let authorization):
                        user = try await appleAuthUsecase.appleLogin(authorization: authorization.value)
                    }

                    await onLoginSuccess(user)
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setSubmitting(false))
            }
        )
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setSubmitting(let isSubmitting):
            newState.isSubmitting = isSubmitting
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        }

        return newState
    }
}
