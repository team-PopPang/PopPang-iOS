import Compound
import Foundation

@Compound
final class FavoritesFeatureCompound {
    enum Action: Sendable {
        case onAppear
        case refresh
    }

    enum Reaction: Sendable {
        case setLoading(Bool)
    }

    struct State: Equatable, Sendable {
        var isLoading = false
    }

    var state = State()

    init() {}

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear, .refresh:
            return .concat(.just(.setLoading(true)), .just(.setLoading(false)))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        }

        return newState
    }
}
