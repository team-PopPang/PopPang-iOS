import ComposableArchitecture
import Domain
import Foundation
import Kingfisher

@Reducer
public struct PopupDetailFeature {
    @ObservableState
    public struct State: Equatable, Sendable {
        var userUuid: String
        var popup: Popup
        var relatedPopupList: [Popup] = []
        var isLoading = false
        var isDeactivating = false
        var didDeactivate = false
        var hasLoaded = false
        var errorMessage: String?

        public init(
            userUuid: String,
            popup: Popup
        ) {
            self.userUuid = userUuid
            self.popup = popup
        }
    }

    public enum Action: Equatable, Sendable {
        case onAppear
        case toggleLike
        case deactivatePopup
        case relatedPopupListLoaded([Popup])
        case favoriteUpdated(isFavorited: Bool, favoriteCount: Int)
        case deactivateCompleted
        case loadingChanged(Bool)
        case deactivatingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable, Sendable {
            case favoriteChanged(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        }
    }

    @Dependency(\.popupDetailClient) private var popupDetailClient: PopupDetailClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasLoaded == false else { return .none }
                state.hasLoaded = true
                state.isLoading = true
                state.didDeactivate = false
                state.errorMessage = nil
                return loadPopupDetail(state: state)

            case .toggleLike:
                let previousPopup = state.popup
                let nextIsFavorited = !previousPopup.isFavorited
                let nextFavoriteCount = nextIsFavorited
                    ? previousPopup.favoriteCount + 1
                    : max(0, previousPopup.favoriteCount - 1)

                state.popup.isFavorited = nextIsFavorited
                state.popup.favoriteCount = nextFavoriteCount

                return .merge(
                    .send(.delegate(.favoriteChanged(
                        popupUuid: previousPopup.popupUuid,
                        isFavorited: nextIsFavorited,
                        favoriteCount: nextFavoriteCount
                    ))),
                    toggleLike(
                        userUuid: state.userUuid,
                        previousPopup: previousPopup
                    )
                )

            case .deactivatePopup:
                state.isDeactivating = true
                state.errorMessage = nil
                return deactivatePopup(popupUuid: state.popup.popupUuid)

            case .relatedPopupListLoaded(let popups):
                state.relatedPopupList = popups
                state.errorMessage = nil
                return .none

            case let .favoriteUpdated(isFavorited, favoriteCount):
                state.popup.isFavorited = isFavorited
                state.popup.favoriteCount = favoriteCount
                return .none

            case .deactivateCompleted:
                state.isDeactivating = false
                state.didDeactivate = true
                state.errorMessage = nil
                return .none

            case .loadingChanged(let isLoading):
                state.isLoading = isLoading
                return .none

            case .deactivatingChanged(let isDeactivating):
                state.isDeactivating = isDeactivating
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

private extension PopupDetailFeature {
    func loadPopupDetail(state: State) -> Effect<Action> {
        let popupDetailClient = popupDetailClient

        return .run { [state, popupDetailClient] send in
            prefetchImages(urls: state.popup.imageUrlList)

            do {
                async let increaseViewCount: Void = popupDetailClient.increaseViewCount(state.popup.popupUuid)
                async let relatedPopups = popupDetailClient.getPersonalRelatedPopupList(
                    state.userUuid,
                    state.popup.popupUuid
                )

                _ = try await increaseViewCount
                await send(.relatedPopupListLoaded(try await relatedPopups))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }

            await send(.loadingChanged(false))
        }
    }

    func toggleLike(
        userUuid: String,
        previousPopup: Popup
    ) -> Effect<Action> {
        let popupDetailClient = popupDetailClient

        return .run { [popupDetailClient, userUuid, previousPopup] send in
            do {
                if previousPopup.isFavorited {
                    try await popupDetailClient.removeFavorite(userUuid, previousPopup.popupUuid)
                } else {
                    try await popupDetailClient.addFavorite(userUuid, previousPopup.popupUuid)
                }

                await send(.errorMessageChanged(nil))
            } catch {
                await send(.favoriteUpdated(
                    isFavorited: previousPopup.isFavorited,
                    favoriteCount: previousPopup.favoriteCount
                ))
                await send(.delegate(.favoriteChanged(
                    popupUuid: previousPopup.popupUuid,
                    isFavorited: previousPopup.isFavorited,
                    favoriteCount: previousPopup.favoriteCount
                )))
                await send(.errorMessageChanged(error.localizedDescription))
            }
        }
    }

    func deactivatePopup(popupUuid: String) -> Effect<Action> {
        let popupDetailClient = popupDetailClient

        return .run { [popupDetailClient, popupUuid] send in
            do {
                try await popupDetailClient.deactivatePopup(popupUuid)
                await send(.deactivateCompleted)
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
                await send(.deactivatingChanged(false))
            }
        }
    }
}

private func prefetchImages(urls: [String]) {
    for urlString in urls {
        guard let url = URL(string: urlString) else { continue }

        ImageCache.default.retrieveImage(forKey: url.cacheKey) { result in
            switch result {
            case .success(let value):
                if value.image == nil {
                    KingfisherManager.shared.retrieveImage(with: url) { _ in }
                }
            case .failure:
                KingfisherManager.shared.retrieveImage(with: url) { _ in }
            }
        }
    }
}
