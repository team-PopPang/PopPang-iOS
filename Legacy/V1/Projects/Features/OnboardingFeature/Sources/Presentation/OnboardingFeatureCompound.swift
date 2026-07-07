import Compound
import Foundation

@Compound
final class OnboardingFeatureCompound {
    enum Action {
        case stepChanged(OnboardingStep)
        case nextButtonTapped(OnboardingStep)
    }

    enum Reaction {
        case setStep(OnboardingStep)
    }

    struct State: Equatable {
        var currentStep: OnboardingStep = .keyword
    }

    var state = State()

    init() {}

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .stepChanged(let step):
            return .just(.setStep(step))
        case .nextButtonTapped(let currentStep):
            guard let nextStep = currentStep.next else {
                return .just(.setStep(currentStep))
            }
            return .just(.setStep(nextStep))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setStep(let step):
            newState.currentStep = step
        }

        return newState
    }
}
