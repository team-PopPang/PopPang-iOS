import Compound
import Domain
import Foundation

@Compound
final class ComingPopupDetailCompound {
    enum Action {
        case onAppear
        case toggleLike(Popup)
    }

    enum Reaction {
        case setPopups([Popup])
        case setFavorite(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        var userUuid: String
        var popups: [Popup]
        var errorMessage: String?
    }

    var state: State

    @Dependency private var popupUsecase: PopupUsecaseProtocol

    init(
        userUuid: String,
        popups: [Popup]
    ) {
        self.state = State(
            userUuid: userUuid,
            popups: popups.sorted { $0.startDate < $1.startDate }
        )
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            return updateComingPopups()
        case .toggleLike(let popup):
            return toggleLike(popup: popup)
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setPopups(let popups):
            newState.popups = popups.sorted { $0.startDate < $1.startDate }
        case let .setFavorite(popupUuid, isFavorited, favoriteCount):
            guard let index = newState.popups.firstIndex(where: { $0.popupUuid == popupUuid }) else { break }
            newState.popups[index].isFavorited = isFavorited
            newState.popups[index].favoriteCount = favoriteCount
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        }

        return newState
    }
}

private extension ComingPopupDetailCompound {
    func updateComingPopups() -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .run { [state, popupUsecase] send in
            do {
                let popups = try await popupUsecase.getPersonalUpcomingPopupList(userUuid: state.userUuid)
                await send(.setPopups(popups))
                await send(.setErrorMessage(nil))
            } catch {
                await send(.setErrorMessage(error.localizedDescription))
            }
        }
    }

    func toggleLike(popup: Popup) -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase
        let nextIsFavorited = !popup.isFavorited
        let nextFavoriteCount = nextIsFavorited
            ? popup.favoriteCount + 1
            : max(0, popup.favoriteCount - 1)

        return .concat(
            .just(.setFavorite(
                popupUuid: popup.popupUuid,
                isFavorited: nextIsFavorited,
                favoriteCount: nextFavoriteCount
            )),
            .run { [state, popupUsecase, popup] send in
                do {
                    if popup.isFavorited {
                        try await popupUsecase.removeFavorite(
                            userUuid: state.userUuid,
                            popupUuid: popup.popupUuid
                        )
                    } else {
                        try await popupUsecase.addFavorite(
                            userUuid: state.userUuid,
                            popupUuid: popup.popupUuid
                        )
                    }
                    await send(.setErrorMessage(nil))
                } catch {
                    await send(.setFavorite(
                        popupUuid: popup.popupUuid,
                        isFavorited: popup.isFavorited,
                        favoriteCount: popup.favoriteCount
                    ))
                    await send(.setErrorMessage(error.localizedDescription))
                }
            }
        )
    }
}
