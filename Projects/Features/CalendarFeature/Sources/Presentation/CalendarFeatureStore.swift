import Combine
import Foundation

@MainActor
public final class CalendarFeatureStore: ObservableObject {
    @Published public private(set) var state = CalendarFeatureState()

    public init() {}

    public func send(_ action: CalendarFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: CalendarFeatureAction) -> AsyncStream<CalendarFeatureMutation> {
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
        state: CalendarFeatureState,
        mutation: CalendarFeatureMutation
    ) -> CalendarFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
