import ComposableArchitecture
import Domain
import Foundation
import Kingfisher

@Reducer
struct PopupDetailFeatureReducer {
    @ObservableState
    struct State: Equatable, Sendable {
        var userUuid: String
        var popup: Popup
        var relatedPopupList: [Popup] = []
        var isLoading = false
        var isDeactivating = false
        var didDeactivate = false
        var hasLoaded = false
        var errorMessage: String?

        init(
            userUuid: String,
            popup: Popup
        ) {
            self.userUuid = userUuid
            self.popup = popup
        }
    }

    enum Action: Sendable {
        case onAppear
        case toggleLike
        case deactivatePopup
        case relatedPopupListLoaded([Popup])
        case favoriteUpdated(isFavorited: Bool, favoriteCount: Int)
        case deactivateCompleted
        case loadingChanged(Bool)
        case deactivatingChanged(Bool)
        case errorMessageChanged(String?)
    }

    @Dependencies.Dependency(\.popupDetailClient) private var popupDetailClient: PopupDetailClient

    var body: some Reducer<State, Action> {
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

                return toggleLike(
                    userUuid: state.userUuid,
                    previousPopup: previousPopup
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
            }
        }
    }
}

private extension PopupDetailFeatureReducer {
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

struct PopupDetailClient: Sendable {
    var increaseViewCount: @Sendable (_ popupUuid: String) async throws -> Void
    var getPersonalRelatedPopupList: @Sendable (
        _ userUuid: String,
        _ popupUuid: String
    ) async throws -> [Popup]
    var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    var removeFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    var deactivatePopup: @Sendable (_ popupUuid: String) async throws -> Void
}

extension PopupDetailClient: DependencyKey {
    static var liveValue: PopupDetailClient {
        let popupUsecaseBox = PopupDetailPopupUsecaseBox(DIContainer.shared.resolve(PopupUsecaseProtocol.self))
        let adminUsecaseBox = PopupDetailAdminUsecaseBox(DIContainer.shared.resolve(AdminUsecaseProtocol.self))

        return PopupDetailClient(
            increaseViewCount: { popupUuid in
                try await popupUsecaseBox.usecase.increaseViewCount(popupUuid: popupUuid)
            },
            getPersonalRelatedPopupList: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.getPersonalRelatedPopupList(
                    userUuid: userUuid,
                    popupUuid: popupUuid
                )
            },
            addFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            removeFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            deactivatePopup: { popupUuid in
                try await adminUsecaseBox.usecase.deactivatePopup(popupUuid: popupUuid)
            }
        )
    }
}

extension DependencyValues {
    var popupDetailClient: PopupDetailClient {
        get { self[PopupDetailClient.self] }
        set { self[PopupDetailClient.self] = newValue }
    }
}

private final class PopupDetailPopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}

private final class PopupDetailAdminUsecaseBox: @unchecked Sendable {
    let usecase: AdminUsecaseProtocol

    init(_ usecase: AdminUsecaseProtocol) {
        self.usecase = usecase
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
