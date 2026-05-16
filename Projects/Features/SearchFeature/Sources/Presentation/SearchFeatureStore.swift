import Combine
import Foundation

@MainActor
public final class SearchFeatureStore: ObservableObject {
    @Published public private(set) var state = SearchFeatureState()

    public init() {}

    public func send(_ action: SearchFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: SearchFeatureAction) -> AsyncStream<SearchFeatureMutation> {
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
        state: SearchFeatureState,
        mutation: SearchFeatureMutation
    ) -> SearchFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
