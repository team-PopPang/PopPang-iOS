import Combine
import Foundation

@MainActor
public final class ProfileFeatureStore: ObservableObject {
    @Published public private(set) var state = ProfileFeatureState()

    public init() {}

    public func send(_ action: ProfileFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: ProfileFeatureAction) -> AsyncStream<ProfileFeatureMutation> {
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
        state: ProfileFeatureState,
        mutation: ProfileFeatureMutation
    ) -> ProfileFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
