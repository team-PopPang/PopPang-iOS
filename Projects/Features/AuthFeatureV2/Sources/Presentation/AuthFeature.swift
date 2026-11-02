import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct AuthFeature {
    @ObservableState
    public struct State: Equatable {
        public var isSubmitting = false
        public var errorMessage: String?

        public init(errorMessage: String? = nil) {
            self.errorMessage = errorMessage
        }
    }

    public enum Action {
        case loginTapped(Provider)
        case loginResponse(Result<LoginResult, Error>)
        case errorDismissed
        case delegate(Delegate)

        public enum Delegate: Equatable {
            /// 가입을 마친 사용자가 로그인했다.
            case authenticated(User)
            /// 가입이 필요하다.
            case signupRequired(Provider)
        }
    }

    @Dependency(\.authFeatureClient) private var authFeatureClient: AuthFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .loginTapped(let provider):
                guard !state.isSubmitting else { return .none }
                state.isSubmitting = true
                state.errorMessage = nil
                return .run { [authFeatureClient] send in
                    await send(.loginResponse(Result { try await authFeatureClient.login(provider) }))
                }

            case .loginResponse(.success(.completed(let user))):
                state.isSubmitting = false
                return .send(.delegate(.authenticated(user)))

            case .loginResponse(.success(.pending(let provider))):
                state.isSubmitting = false
                return .send(.delegate(.signupRequired(provider)))

            case .loginResponse(.failure(let error)):
                state.isSubmitting = false
                state.errorMessage = AuthErrorMessage.login(for: error)
                return .none

            case .errorDismissed:
                state.errorMessage = nil
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
