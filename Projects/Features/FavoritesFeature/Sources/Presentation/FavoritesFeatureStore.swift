import Combine
import Foundation

@MainActor
public final class FavoritesFeatureStore: ObservableObject {
    @Published public private(set) var state = FavoritesFeatureState()

    public init() {}

    public func send(_ action: FavoritesFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: FavoritesFeatureAction) -> AsyncStream<FavoritesFeatureMutation> {
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
        state: FavoritesFeatureState,
        mutation: FavoritesFeatureMutation
    ) -> FavoritesFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
