import Combine
import Foundation

@MainActor
public final class PopupDetailFeatureStore: ObservableObject {
    @Published public private(set) var state = PopupDetailFeatureState()

    public init() {}

    public func send(_ action: PopupDetailFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: PopupDetailFeatureAction) -> AsyncStream<PopupDetailFeatureMutation> {
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
        state: PopupDetailFeatureState,
        mutation: PopupDetailFeatureMutation
    ) -> PopupDetailFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
