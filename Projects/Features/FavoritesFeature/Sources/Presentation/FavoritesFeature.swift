import ComposableArchitecture
import Domain
import Foundation

@Reducer
public struct FavoritesFeature {
    @ObservableState
    public struct State: Equatable {
        public var favoritePopups: [Popup] = []
        public var selectedPopups: [Popup] = []
        public var selectedDate: Date = Date()
        public var popupEventCounts: [Date: Int] = [:]
        public var isLoading = false
        public var errorMessage: String?

        public init() {}

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.favoritePopups == rhs.favoritePopups
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

    @Dependency(\.favoritesFeatureClient) private var favoritesFeatureClient: FavoritesFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return getFavoritePopups()

            case .dateSelected(let date):
                state.selectedDate = date
                state.selectedPopups = Self.popups(from: state.favoritePopups, on: date)
                return .none

            case .toggleLike(let popup):
                state.isLoading = true
                return toggleLike(popup: popup)

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
    func getFavoritePopups() -> Effect<Action> {
        let favoritesFeatureClient = favoritesFeatureClient

        return .run { [favoritesFeatureClient] send in
            do {
                let popups = try await favoritesFeatureClient.getFavoriteList()
                await send(.favoritePopupsLoaded(popups))
            } catch {
                await send(.errorMessageChanged(Self.loadFailedMessage))
            }

            await send(.loadingChanged(false))
        }
    }

    func toggleLike(popup: Popup) -> Effect<Action> {
        let favoritesFeatureClient = favoritesFeatureClient

        return .run { [popup, favoritesFeatureClient] send in
            do {
                if popup.isFavorited {
                    try await favoritesFeatureClient.removeFavorite(popup.popupUuid)
                } else {
                    try await favoritesFeatureClient.addFavorite(popup.popupUuid)
                }

                let popups = try await favoritesFeatureClient.getFavoriteList()
                await send(.favoritePopupsLoaded(popups))
                await send(.errorMessageChanged(nil))
            } catch {
                // 이미 찜했거나(409 4101) 이미 해제된(404 4102) 경우처럼 화면과 서버가 어긋났을 수 있어 목록을 다시 받는다.
                // 다시 받기도 실패하면 안내만 남기고 지금 목록을 둔다.
                if let popups = try? await favoritesFeatureClient.getFavoriteList() {
                    await send(.favoritePopupsLoaded(popups))
                }
                await send(.errorMessageChanged(Self.toggleFailedMessage))
            }

            await send(.loadingChanged(false))
        }
    }

    static var loadFailedMessage: String {
        String(localized: "찜한 팝업을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var toggleFailedMessage: String {
        String(localized: "찜을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
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
