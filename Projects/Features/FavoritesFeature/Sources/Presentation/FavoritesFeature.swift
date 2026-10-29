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
        /// 서버에서 마지막으로 받은 찜 목록. 화면에는 숨길 팝업을 뺀 `favoritePopups`를 보여 준다.
        var loadedPopups: [Popup] = []
        /// 해제 요청을 보내고 응답을 기다리는 팝업. 어떤 목록 응답이 와도 화면에서 뺀다.
        var removingPopupUuids: Set<String> = []

        public init() {}

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.favoritePopups == rhs.favoritePopups
                && lhs.selectedPopups == rhs.selectedPopups
                && lhs.selectedDate == rhs.selectedDate
                && lhs.popupEventCounts == rhs.popupEventCounts
                && lhs.isLoading == rhs.isLoading
                && lhs.errorMessage == rhs.errorMessage
                && lhs.loadedPopups == rhs.loadedPopups
                && lhs.removingPopupUuids == rhs.removingPopupUuids
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
        case removeFavoriteFinished(popupUuid: String, RemoveResult)
        case loadingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable {
            case alertRequested
            case popupSelected(Popup)
            case browsePopupsRequested
        }
    }

    public enum RemoveResult: Equatable, Sendable {
        case succeeded
        /// 다시 로그인해야 한다. 토큰이 지워져 목록을 다시 받아도 실패한다.
        case loginRequired
        case failed
    }

    private enum CancelID {
        case load
    }

    @Dependency(\.favoritesFeatureClient) private var favoritesFeatureClient: FavoritesFeatureClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                state.errorMessage = nil
                return loadFavoritePopups()

            case .dateSelected(let date):
                state.selectedDate = date
                state.selectedPopups = Self.popups(from: state.favoritePopups, on: date)
                return .none

            case .toggleLike(let popup):
                // 찜 탭의 팝업은 모두 찜한 팝업이라 하트는 해제만 한다. 찜하지 않은 팝업이 오면 누르지 않은 것으로 본다.
                guard popup.isFavorited, !state.removingPopupUuids.contains(popup.popupUuid) else { return .none }
                state.errorMessage = nil
                // 응답을 기다리지 않고 먼저 숨긴다.
                state.removingPopupUuids.insert(popup.popupUuid)
                applyVisiblePopups(state: &state)
                return removeFavorite(popupUuid: popup.popupUuid)

            case .removeFavoriteFinished(let popupUuid, let result):
                state.removingPopupUuids.remove(popupUuid)
                switch result {
                case .succeeded:
                    state.loadedPopups.removeAll { $0.popupUuid == popupUuid }
                    applyVisiblePopups(state: &state)
                    // 해제 도중에 보낸 목록 요청은 해제 전 상태라 이 팝업이 들어 있을 수 있다. 취소하고 새로 받는다.
                    return loadFavoritePopups()

                case .loginRequired:
                    // 숨긴 팝업을 다시 보여 준다. 로그인 화면 전환은 AppFeature가 한다.
                    applyVisiblePopups(state: &state)
                    state.errorMessage = Self.removeFailedMessage
                    return .none

                case .failed:
                    // 숨긴 팝업을 다시 보여 주고, 이미 해제된 찜(404 4102)처럼 서버와 어긋났을 수 있어 목록을 다시 받는다.
                    applyVisiblePopups(state: &state)
                    state.errorMessage = Self.removeFailedMessage
                    return loadFavoritePopups()
                }

            case .popupSelected(let popup):
                return .send(.delegate(.popupSelected(popup)))

            case .alertTapped:
                return .send(.delegate(.alertRequested))

            case .browsePopupsTapped:
                return .send(.delegate(.browsePopupsRequested))

            case .favoritePopupsLoaded(let popups):
                state.loadedPopups = popups
                applyVisiblePopups(state: &state)
                // 목록을 받았으니 목록 실패 문구는 지운다. 해제 실패 문구는 다시 받은 뒤에도 남긴다.
                if state.errorMessage == Self.loadFailedMessage {
                    state.errorMessage = nil
                }
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
    /// 찜 목록을 받는다. 앞서 보낸 목록 요청은 취소해 가장 최근 요청의 응답만 반영한다.
    func loadFavoritePopups() -> Effect<Action> {
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
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

    /// 해제 요청은 취소 ID가 없어 store가 사라질 때만 취소된다. 그때는 상태도 함께 사라지므로 취소를 따로 처리하지 않는다.
    func removeFavorite(popupUuid: String) -> Effect<Action> {
        let favoritesFeatureClient = favoritesFeatureClient

        return .run { [favoritesFeatureClient] send in
            do {
                try await favoritesFeatureClient.removeFavorite(popupUuid)
                await send(.removeFavoriteFinished(popupUuid: popupUuid, .succeeded))
            } catch is AuthSessionError {
                await send(.removeFavoriteFinished(popupUuid: popupUuid, .loginRequired))
            } catch {
                await send(.removeFavoriteFinished(popupUuid: popupUuid, .failed))
            }
        }
    }

    static var loadFailedMessage: String {
        String(localized: "찜한 팝업을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var removeFailedMessage: String {
        String(localized: "찜을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    /// 서버 목록에서 해제 중인 팝업을 빼고 화면 상태를 다시 만든다.
    func applyVisiblePopups(state: inout State) {
        let popups = state.loadedPopups.filter { !state.removingPopupUuids.contains($0.popupUuid) }
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
