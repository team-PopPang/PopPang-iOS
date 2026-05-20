import Compound
import Foundation

@Compound
final class HomeFeatureCompound {
    enum Action: Sendable {
        case onAppear
        case refresh
        case searchButtonTapped
        case popupDetailButtonTapped
        case routeHandled
    }

    enum Reaction: Sendable {
        case setLoading(Bool)
        case setRoute(HomeFeatureRoute?)
    }

    struct State: Equatable, Sendable {
        var isLoading = false
        var route: HomeFeatureRoute?
    }

    var state = State()

    init() {}

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear, .refresh:
            return .concat(.just(.setLoading(true)), .just(.setLoading(false)))
        case .searchButtonTapped:
            return .just(.setRoute(.search))
        case .popupDetailButtonTapped:
            return .just(.setRoute(.popupDetail))
        case .routeHandled:
            return .just(.setRoute(nil))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setRoute(let route):
            newState.route = route
        }

        return newState
    }
}
