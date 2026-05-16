import Combine
import Foundation

@MainActor
public final class MapFeatureStore: ObservableObject {
    @Published public private(set) var state = MapFeatureState()

    public init() {}

    public func send(_ action: MapFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: MapFeatureAction) -> AsyncStream<MapFeatureMutation> {
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
        state: MapFeatureState,
        mutation: MapFeatureMutation
    ) -> MapFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
