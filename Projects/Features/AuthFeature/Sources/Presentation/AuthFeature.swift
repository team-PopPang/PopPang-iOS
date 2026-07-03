import AuthenticationServices
import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct AuthFeature {
    public struct AppleAuthorization: @unchecked Sendable {
        let value: ASAuthorization

        public init(_ value: ASAuthorization) {
            self.value = value
        }
    }

    @ObservableState
    public struct State: Equatable {
        public var isSubmitting = false
        public var errorMessage: String?

        public init() {}
    }

    public enum Action {
        case kakaoLoginTapped
        case googleLoginTapped
        case appleLoginTapped(AppleAuthorization)
        case loginResponse(Result<User, Error>)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case authenticated(User)
        }
    }

    @Dependency(\.authFeatureClient) private var authFeatureClient: AuthFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .kakaoLoginTapped:
                state.isSubmitting = true
                state.errorMessage = nil
                return .run { [authFeatureClient] send in
                    do {
                        let user = try await authFeatureClient.kakaoLogin()
                        await send(.loginResponse(.success(user)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }

            case .googleLoginTapped:
                state.isSubmitting = true
                state.errorMessage = nil
                return .run { [authFeatureClient] send in
                    do {
                        let user = try await authFeatureClient.googleLogin()
                        await send(.loginResponse(.success(user)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }

            case .appleLoginTapped(let authorization):
                state.isSubmitting = true
                state.errorMessage = nil
                return .run { [authFeatureClient] send in
                    do {
                        let user = try await authFeatureClient.appleLogin(authorization.value)
                        await send(.loginResponse(.success(user)))
                    } catch {
                        await send(.loginResponse(.failure(error)))
                    }
                }

            case .loginResponse(.success(let user)):
                state.isSubmitting = false
                return .send(.delegate(.authenticated(user)))

            case .loginResponse(.failure(let error)):
                state.isSubmitting = false
                state.errorMessage = error.localizedDescription
                return .none

            case .delegate:
                return .none
            }
        }
    }
}
