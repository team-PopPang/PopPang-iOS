import Combine
import Foundation

@MainActor
public final class OnboardingFeatureStore: ObservableObject {
    @Published public private(set) var state = OnboardingFeatureState()

    public init() {}

    public func send(_ action: OnboardingFeatureAction) {
        Task {
            for await mutation in mutate(action: action) {
                state = reduce(state: state, mutation: mutation)
            }
        }
    }

    public func mutate(action: OnboardingFeatureAction) -> AsyncStream<OnboardingFeatureMutation> {
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
        state: OnboardingFeatureState,
        mutation: OnboardingFeatureMutation
    ) -> OnboardingFeatureState {
        var newState = state

        switch mutation {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
