import Combine
import Foundation

@MainActor
public final class AuthFeatureStore: ObservableObject {
    @Published public private(set) var state = AuthFeatureState()

    public init() {}

    public func send(_ action: AuthFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: AuthFeatureAction) -> AsyncStream<AuthFeatureMutation> {
        switch action {
        case .onAppear, .refresh:
            return AsyncStream { continuation in
                continuation.yield(.setLoading(true))
                continuation.yield(.setLoading(false))
                continuation.finish()
            }
        }
    }

    public func reduce(
        state: AuthFeatureState,
        mutation: AuthFeatureMutation
    ) -> AuthFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
