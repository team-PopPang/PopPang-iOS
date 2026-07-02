import ComposableArchitecture
import Core
import Domain
import Foundation

@Reducer
public struct FavoritesFeature {
    @ObservableState
    public struct State: Equatable {
        @Shared var session: UserSession
        public var favoritePopups: [Popup] = []
        public var selectedPopups: [Popup] = []
        public var selectedDate: Date = Date()
        public var popupEventCounts: [Date: Int] = [:]
        public var isLoading = false
        public var errorMessage: String?

        public init(session: Shared<UserSession>) {
            self._session = session
        }

        public var userUuid: String {
            sessionContext.userUuid
        }

        private var sessionContext: SessionContext {
            guard let context = session.context else {
                preconditionFailure("FavoritesFeature requires a logged in session.")
            }
            return context
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.userUuid == rhs.userUuid
                && lhs.favoritePopups == rhs.favoritePopups
                && lhs.selectedPopups == rhs.selectedPopups
                && lhs.selectedDate == rhs.selectedDate
                && lhs.popupEventCounts == rhs.popupEventCounts
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
        }
    }

    public enum Action {
        case onAppear
        case dateSelected(Date)
        case toggleLike(Popup)
        case popupSelected(Popup)
        case alertTapped
        case browsePopupsTapped
        case favoritePopupsLoaded([Popup])
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case alertRequested
            case popupSelected(Popup)
            case browsePopupsRequested
        }
    }

    @Dependencies.Dependency(\.favoritesFeatureClient) private var favoritesFeatureClient: FavoritesFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return getFavoritePopups(state: state)

            case .dateSelected(let date):
                state.selectedDate = date
                state.selectedPopups = Self.popups(from: state.favoritePopups, on: date)
                return .none

            case .toggleLike(let popup):
                state.isLoading = true
                return toggleLike(state: state, popup: popup)

            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))

            case .alertTapped:
                return .send(.delegate(.alertRequested))

            case .browsePopupsTapped:
                return .send(.delegate(.browsePopupsRequested))

            case .favoritePopupsLoaded(let popups):
                applyPopups(popups, state: &state)
                state.errorMessage = nil
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none

            case .errorMessageChanged(let errorMessage):
                state.errorMessage = errorMessage
                return .none

            case .delegate:
                return .none
            }
        }
    }
}

private extension FavoritesFeature {
    func getFavoritePopups(state: State) -> Effect<Action> {
        let favoritesFeatureClient = favoritesFeatureClient

        return .run { [state, favoritesFeatureClient] send in
            do {
                let popups = try await favoritesFeatureClient.getFavoriteList(state.userUuid)
                await send(.favoritePopupsLoaded(popups))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func toggleLike(state: State, popup: Popup) -> Effect<Action> {
        let favoritesFeatureClient = favoritesFeatureClient

        return .run { [state, popup, favoritesFeatureClient] send in
            do {
                if popup.isFavorited {
                    try await favoritesFeatureClient.removeFavorite(state.userUuid, popup.popupUuid)
                } else {
                    try await favoritesFeatureClient.addFavorite(state.userUuid, popup.popupUuid)
                }

                let popups = try await favoritesFeatureClient.getFavoriteList(state.userUuid)
                await send(.favoritePopupsLoaded(popups))
                await send(.errorMessageChanged(nil))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func applyPopups(_ popups: [Popup], state: inout State) {
        state.favoritePopups = popups
        state.popupEventCounts = Self.eventCounts(from: popups)
        state.selectedPopups = Self.popups(from: popups, on: state.selectedDate)
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
