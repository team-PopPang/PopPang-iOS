import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct ComingPopupDetailFeature {
    @ObservableState
    public struct State: Equatable, Sendable {
        var userUuid: String
        var popups: [Popup]
        var isLoading = false
        var errorMessage: String?

        public init(
            userUuid: String,
            popups: [Popup]
        ) {
            self.userUuid = userUuid
            self.popups = popups.sorted { $0.startDate < $1.startDate }
        }
    }

    public enum Action: Equatable, Sendable {
        case onAppear
        case toggleLike(Popup)
        case popupsLoaded([Popup])
        case favoriteUpdated(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        case errorMessageChanged(String?)
    }

    @Dependency(\.homePopupClient) private var popupClient: HomePopupClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return updateComingPopups(userUuid: state.userUuid)

            case .toggleLike(let popup):
                let currentPopup = state.popups.first { $0.popupUuid == popup.popupUuid } ?? popup
                let nextIsFavorited = !currentPopup.isFavorited
                let nextFavoriteCount = nextIsFavorited
                    ? currentPopup.favoriteCount + 1
                    : max(0, currentPopup.favoriteCount - 1)

                updateFavorite(
                    in: &state.popups,
                    popupUuid: currentPopup.popupUuid,
                    isFavorited: nextIsFavorited,
                    favoriteCount: nextFavoriteCount
                )

                return toggleLike(
                    userUuid: state.userUuid,
                    popup: currentPopup
                )

            case .popupsLoaded(let popups):
                state.popups = popups.sorted { $0.startDate < $1.startDate }
                state.isLoading = false
                state.errorMessage = nil
                return .none

            case let .favoriteUpdated(popupUuid, isFavorited, favoriteCount):
                updateFavorite(
                    in: &state.popups,
                    popupUuid: popupUuid,
                    isFavorited: isFavorited,
                    favoriteCount: favoriteCount
                )
                return .none

            case .errorMessageChanged(let errorMessage):
                state.isLoading = false
                state.errorMessage = errorMessage
                return .none
            }
        }
    }
}

private extension ComingPopupDetailFeature {
    func updateComingPopups(userUuid: String) -> Effect<Action> {
        let popupClient = popupClient

        return .run { [popupClient, userUuid] send in
            do {
                let popups = try await popupClient.getPersonalUpcomingPopupList(userUuid)
                await send(.popupsLoaded(popups))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }
        }
    }

    func toggleLike(
        userUuid: String,
        popup: Popup
    ) -> Effect<Action> {
        let popupClient = popupClient

        return .run { [popupClient, userUuid, popup] send in
            do {
                if popup.isFavorited {
                    try await popupClient.removeFavorite(userUuid, popup.popupUuid)
                } else {
                    try await popupClient.addFavorite(userUuid, popup.popupUuid)
                }
                await send(.errorMessageChanged(nil))
            } catch {
                await send(.favoriteUpdated(
                    popupUuid: popup.popupUuid,
                    isFavorited: popup.isFavorited,
                    favoriteCount: popup.favoriteCount
                ))
                await send(.errorMessageChanged(error.localizedDescription))
            }
        }
    }

    func updateFavorite(
        in popups: inout [Popup],
        popupUuid: String,
        isFavorited: Bool,
        favoriteCount: Int
    ) {
        guard let index = popups.firstIndex(where: { $0.popupUuid == popupUuid }) else { return }
        popups[index].isFavorited = isFavorited
        popups[index].favoriteCount = favoriteCount
    }
}
