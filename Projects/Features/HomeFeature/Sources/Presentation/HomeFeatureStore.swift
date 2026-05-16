import Combine
import Foundation

@MainActor
public final class HomeFeatureStore: ObservableObject {
    @Published public private(set) var state = HomeFeatureState()

    public init() {}

    public func send(_ action: HomeFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: HomeFeatureAction) -> AsyncStream<HomeFeatureMutation> {
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
        state: HomeFeatureState,
        mutation: HomeFeatureMutation
    ) -> HomeFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
