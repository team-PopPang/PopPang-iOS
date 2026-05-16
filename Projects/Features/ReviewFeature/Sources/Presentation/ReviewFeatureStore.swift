import Combine
import Foundation

@MainActor
public final class ReviewFeatureStore: ObservableObject {
    @Published public private(set) var state = ReviewFeatureState()

    public init() {}

    public func send(_ action: ReviewFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: ReviewFeatureAction) -> AsyncStream<ReviewFeatureMutation> {
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
        state: ReviewFeatureState,
        mutation: ReviewFeatureMutation
    ) -> ReviewFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
