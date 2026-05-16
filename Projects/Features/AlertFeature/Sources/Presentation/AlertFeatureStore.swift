import Combine
import Foundation

@MainActor
public final class AlertFeatureStore: ObservableObject {
    @Published public private(set) var state = AlertFeatureState()

    public init() {}

    public func send(_ action: AlertFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: AlertFeatureAction) -> AsyncStream<AlertFeatureMutation> {
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
        state: AlertFeatureState,
        mutation: AlertFeatureMutation
    ) -> AlertFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
