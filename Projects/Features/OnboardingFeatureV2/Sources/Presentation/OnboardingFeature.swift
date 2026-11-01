import ComposableArchitecture
import Foundation

@Reducer
public struct OnboardingFeature {
    @ObservableState
    public struct State: Equatable {
        public var currentStep: OnboardingStep = .keyword

        public init() {}
    }

    public enum Action: Equatable {
        case stepChanged(OnboardingStep)
        case nextTapped
        case skipTapped
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case authRequested
        }
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .stepChanged(let step):
                state.currentStep = step
                return .none

            case .nextTapped:
                guard let nextStep = state.currentStep.next else {
                    return .send(.delegate(.authRequested))
                }
                state.currentStep = nextStep
                return .none

            case .skipTapped:
                return .send(.delegate(.authRequested))

            case .delegate:
                return .none
            }
        }
    }
}
