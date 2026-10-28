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
        /// 해제 요청을 보내고 응답을 기다리는 팝업
        var removingPopupUuids: Set<String> = []
        /// 이번에 화면을 연 뒤 해제가 끝난 팝업. 해제 전에 보낸 목록 요청의 응답이 늦게 와도 다시 보이지 않게 한다.
        var removedPopupUuids: Set<String> = []

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
                && lhs.removedPopupUuids == rhs.removedPopupUuids
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
                // 해제가 끝난 팝업은 서버 목록에도 없으므로 새로 받는 목록부터는 숨기지 않아도 된다.
                state.removedPopupUuids = []
                return loadFavoritePopups()

            case .dateSelected(let date):
                state.selectedDate = date
                state.selectedPopups = Self.popups(from: state.favoritePopups, on: date)
                return .none

            case .toggleLike(let popup):
                // 찜 탭의 팝업은 모두 찜한 팝업이라 하트는 항상 해제다.
                guard !state.removingPopupUuids.contains(popup.popupUuid),
                      !state.removedPopupUuids.contains(popup.popupUuid)
                else {
                    return .none
                }
                state.errorMessage = nil
                // 응답을 기다리지 않고 먼저 숨긴다.
                state.removingPopupUuids.insert(popup.popupUuid)
                applyVisiblePopups(state: &state)
                return removeFavorite(popupUuid: popup.popupUuid)

            case .removeFavoriteFinished(let popupUuid, let result):
                state.removingPopupUuids.remove(popupUuid)
                switch result {
                case .succeeded:
                    state.removedPopupUuids.insert(popupUuid)
                    applyVisiblePopups(state: &state)
                    return .none

                case .loginRequired:
                    // 숨긴 팝업을 다시 보여 준다. 로그인 화면 전환은 AppFeature가 한다.
                    applyVisiblePopups(state: &state)
                    state.errorMessage = Self.removeFailedMessage
                    return .none

                case .failed:
                    // 숨긴 팝업을 다시 보여 주고, 이미 해제된 찜(404 4102)처럼 서버와 어긋났을 수 있어 목록을 다시 받는다.
                    applyVisiblePopups(state: &state)
                    state.errorMessage = Self.removeFailedMessage
                    return loadFavoritePopups(showsFailure: false)
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
    /// - Parameter showsFailure: 실패하면 목록 실패 문구를 보여 줄지. 해제 실패 뒤 다시 받을 때는 해제 실패 문구를 그대로 둔다.
    func loadFavoritePopups(showsFailure: Bool = true) -> Effect<Action> {
        let favoritesFeatureClient = favoritesFeatureClient

        return .run { [favoritesFeatureClient] send in
            do {
                let popups = try await favoritesFeatureClient.getFavoriteList()
                await send(.favoritePopupsLoaded(popups))
            } catch {
                if showsFailure {
                    await send(.errorMessageChanged(Self.loadFailedMessage))
                }
            }

            await send(.loadingChanged(false))
        }
        .cancellable(id: CancelID.load, cancelInFlight: true)
    }

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

    /// 서버 목록에서 해제 중이거나 해제된 팝업을 빼고 화면 상태를 다시 만든다.
    func applyVisiblePopups(state: inout State) {
        let hidden = state.removingPopupUuids.union(state.removedPopupUuids)
        let popups = state.loadedPopups.filter { !hidden.contains($0.popupUuid) }
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
