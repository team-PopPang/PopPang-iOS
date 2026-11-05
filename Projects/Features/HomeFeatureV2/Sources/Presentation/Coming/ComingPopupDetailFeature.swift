import ComposableArchitecture
import Core
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
        /// 찜 요청을 보내고 응답을 기다리는 팝업. 응답 전에 같은 하트를 다시 누르면 무시한다 (V2 찜은 중복 요청을 409·404로 거절).
        var favoriteInFlight: Set<String> = []

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
        case favoriteRequestFinished(popupUuid: String)
        case errorMessageChanged(String?)
    }

    @Dependency(\.homePopupClient) private var popupClient: HomePopupClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return updateComingPopups()

            case .toggleLike(let popup):
                guard !state.favoriteInFlight.contains(popup.popupUuid) else { return .none }
                state.favoriteInFlight.insert(popup.popupUuid)
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

                return toggleLike(popup: currentPopup)

            case .favoriteRequestFinished(let popupUuid):
                state.favoriteInFlight.remove(popupUuid)
                return .none

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

extension ComingPopupDetailFeature {
    /// 로그인이 끊긴 실패는 알림을 띄우지 않는다. 로그인 화면 전환은 AppFeature가 세션 이벤트로 한다.
    static func message(for error: Error, fallback: String) -> String? {
        error is AuthSessionError ? nil : fallback
    }

    static var loadFailedMessage: String {
        String(localized: "오픈 예정 팝업을 불러오지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }

    static var favoriteFailedMessage: String {
        String(localized: "찜을 바꾸지 못했어요. 잠시 후 다시 시도해 주세요.", bundle: .module)
    }
}

private extension ComingPopupDetailFeature {
    func updateComingPopups() -> Effect<Action> {
        let popupClient = popupClient

        return .run { [popupClient] send in
            do {
                let popups = try await popupClient.getUpcomingPopupList()
                await send(.popupsLoaded(popups))
            } catch {
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.loadFailedMessage)))
            }
        }
    }

    func toggleLike(popup: Popup) -> Effect<Action> {
        let popupClient = popupClient

        return .run { [popupClient, popup] send in
            do {
                if popup.isFavorited {
                    try await popupClient.removeFavorite(popup.popupUuid)
                } else {
                    try await popupClient.addFavorite(popup.popupUuid)
                }
            } catch {
                await send(.favoriteUpdated(
                    popupUuid: popup.popupUuid,
                    isFavorited: popup.isFavorited,
                    favoriteCount: popup.favoriteCount
                ))
                await send(.errorMessageChanged(Self.message(for: error, fallback: Self.favoriteFailedMessage)))
            }
            await send(.favoriteRequestFinished(popupUuid: popup.popupUuid))
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

