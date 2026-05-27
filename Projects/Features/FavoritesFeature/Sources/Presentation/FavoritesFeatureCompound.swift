import Compound
import Domain
import Foundation

@Compound
final class FavoritesFeatureCompound {
    enum Action {
        case onAppear
        case refresh
        case dateSelected(Date)
        case toggleLike(Popup)
        case setErrorMessage(String?)
    }

    enum Reaction {
        case setDidPreload(Bool)
        case setLoading(Bool)
        case setFavoritePopups([Popup])
        case setSelectedDate(Date)
        case setSelectedPopups([Popup])
        case setPopupEventCounts([Date: Int])
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        var userUuid: String
        var favoritePopups: [Popup] = []
        var selectedPopups: [Popup] = []
        var selectedDate: Date = Date()
        var popupEventCounts: [Date: Int] = [:]
        var didPreload = false
        var isLoading = false
        var errorMessage: String?
    }

    var state: State

    @Dependency private var popupUsecase: PopupUsecaseProtocol

    init(userUuid: String) {
        self.state = State(userUuid: userUuid)
    }

    @MainActor
    func preload() {
        send(.onAppear)
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            guard !state.didPreload else { return Self.emptyReactionStream() }

            return .concat(
                .just(.setDidPreload(true)),
                getFavoritePopups()
            )

        case .refresh:
            return getFavoritePopups()

        case .dateSelected(let date):
            return .concat(
                .just(.setSelectedDate(date)),
                .just(.setSelectedPopups(Self.popups(from: state.favoritePopups, on: date)))
            )

        case .toggleLike(let popup):
            return toggleLike(popup: popup)

        case .setErrorMessage(let errorMessage):
            return .just(.setErrorMessage(errorMessage))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setDidPreload(let didPreload):
            newState.didPreload = didPreload
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setFavoritePopups(let popups):
            newState.favoritePopups = popups
        case .setSelectedDate(let date):
            newState.selectedDate = date
        case .setSelectedPopups(let popups):
            newState.selectedPopups = popups
        case .setPopupEventCounts(let counts):
            newState.popupEventCounts = counts
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        }

        return newState
    }
}

private extension FavoritesFeatureCompound {
    static func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func getFavoritePopups() -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .concat(
            .just(.setLoading(true)),
            .just(.setErrorMessage(nil)),
            .run { [state, popupUsecase] send in
                do {
                    let popups = try await popupUsecase.getFavoriteList(userUuid: state.userUuid)
                    await send(.setFavoritePopups(popups))
                    await send(.setPopupEventCounts(Self.eventCounts(from: popups)))
                    await send(.setSelectedPopups(Self.popups(from: popups, on: state.selectedDate)))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func toggleLike(popup: Popup) -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .concat(
            .just(.setLoading(true)),
            .run { [state, popupUsecase] send in
                do {
                    if popup.isFavorited {
                        try await popupUsecase.removeFavorite(userUuid: state.userUuid, popupUuid: popup.popupUuid)
                    } else {
                        try await popupUsecase.addFavorite(userUuid: state.userUuid, popupUuid: popup.popupUuid)
                    }

                    let popups = try await popupUsecase.getFavoriteList(userUuid: state.userUuid)
                    await send(.setFavoritePopups(popups))
                    await send(.setPopupEventCounts(Self.eventCounts(from: popups)))
                    await send(.setSelectedPopups(Self.popups(from: popups, on: state.selectedDate)))
                    await send(.setErrorMessage(nil))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    static func eventCounts(from popups: [Popup]) -> [Date: Int] {
        var counts: [Date: Int] = [:]
        let calendar = Calendar.current

        for popup in popups {
            var date = calendar.startOfDay(for: popup.startDate)
            let end = calendar.startOfDay(for: popup.endDate)

            while date <= end {
                counts[date, default: 0] += 1
                guard let nextDate = calendar.date(byAdding: .day, value: 1, to: date) else { break }
                date = nextDate
            }
        }

        return counts
    }

    static func popups(from popups: [Popup], on date: Date) -> [Popup] {
        popups.filter { popup in
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: popup.startDate)
            let end = calendar.startOfDay(for: popup.endDate)
            let target = calendar.startOfDay(for: date)
            return target >= start && target <= end
        }
    }
}
