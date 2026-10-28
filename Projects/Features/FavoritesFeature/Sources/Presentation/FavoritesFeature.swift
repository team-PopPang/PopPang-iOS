import ComposableArchitecture
import Core
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
                state.errorMessage = nil
                if popup.isFavorited {
                    // 응답을 기다리지 않고 먼저 뺀다. 같은 하트를 다시 눌러 해제 요청이 두 번 가지 않는다.
                    applyPopups(state.favoritePopups.filter { $0.popupUuid != popup.popupUuid }, state: &state)
                }
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
            } catch is CancellationError {
                // 화면이 사라져 취소됐다. 안내하지 않는다.
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
                    // 목록에서는 이미 뺐으므로 성공하면 더 할 일이 없다.
                    try await favoritesFeatureClient.removeFavorite(popup.popupUuid)
                } else {
                    try await favoritesFeatureClient.addFavorite(popup.popupUuid)
                    let popups = try await favoritesFeatureClient.getFavoriteList()
                    await send(.favoritePopupsLoaded(popups))
                }
            } catch is CancellationError {
                // 화면이 사라져 취소됐다. 안내하지 않는다.
            } catch is AuthSessionError {
                // 토큰이 지워져 목록을 다시 받아도 실패한다. 로그인 화면 전환은 AppFeature가 한다.
                await send(.errorMessageChanged(Self.toggleFailedMessage))
            } catch {
                // 먼저 뺀 팝업을 서버 상태로 되돌린다. 이미 해제된 찜(404 4102)이면 다시 받은 목록에도 없다.
                // 다시 받기도 실패하면 안내만 남기고 지금 목록을 둔다.
                if let popups = try? await favoritesFeatureClient.getFavoriteList() {
                    await send(.favoritePopupsLoaded(popups))
                }
                await send(.errorMessageChanged(Self.toggleFailedMessage))
            }
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
