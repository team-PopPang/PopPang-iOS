import Compound
import Kingfisher
import Domain
import Foundation

@Compound
final class PopupDetailFeatureCompound {
    enum Action {
        case onAppear
        case toggleLike
        case deactivatePopup
        case relatedPopupTapped(Popup)
        case setErrorMessage(String?)
    }

    enum Reaction {
        case setPopup(Popup)
        case setRelatedPopupList([Popup])
        case setLoading(Bool)
        case setDeactivating(Bool)
        case setErrorMessage(String?)
    }

    struct State: Equatable {
        let userUuid: String
        var popup: Popup
        var relatedPopupList: [Popup] = []
        var isLoading = false
        var isDeactivating = false
        var errorMessage: String?
    }

    var state: State

    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Dependency private var adminUsecase: AdminUsecaseProtocol

    private let onSelectRelatedPopup: (String, Popup) -> Void
    private let onDeactivateComplete: () -> Void

    init(
        userUuid: String,
        popup: Popup,
        onSelectRelatedPopup: @escaping (String, Popup) -> Void = { _, _ in },
        onDeactivateComplete: @escaping () -> Void = {}
    ) {
        self.state = State(userUuid: userUuid, popup: popup)
        self.onSelectRelatedPopup = onSelectRelatedPopup
        self.onDeactivateComplete = onDeactivateComplete
    }

    func react(action: Action) -> AsyncStream<Reaction> {
        switch action {
        case .onAppear:
            return onAppear()

        case .toggleLike:
            return toggleLike()

        case .deactivatePopup:
            return deactivatePopup()

        case .relatedPopupTapped(let popup):
            onSelectRelatedPopup(state.userUuid, popup)
            return emptyReactionStream()

        case .setErrorMessage(let errorMessage):
            return .just(.setErrorMessage(errorMessage))
        }
    }

    func reduce(state: State, reaction: Reaction) -> State {
        var newState = state

        switch reaction {
        case .setPopup(let popup):
            newState.popup = popup
        case .setRelatedPopupList(let popups):
            newState.relatedPopupList = popups
        case .setLoading(let isLoading):
            newState.isLoading = isLoading
        case .setDeactivating(let isDeactivating):
            newState.isDeactivating = isDeactivating
        case .setErrorMessage(let errorMessage):
            newState.errorMessage = errorMessage
        }

        return newState
    }
}

private extension PopupDetailFeatureCompound {
    func onAppear() -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .concat(
            .just(.setLoading(true)),
            .run { [state, popupUsecase] send in
                prefetchImages(urls: state.popup.imageUrlList)

                do {
                    async let increaseViewCount: Void = popupUsecase.increaseViewCount(popupUuid: state.popup.popupUuid)
                    async let relatedPopups = popupUsecase.getPersonalRelatedPopupList(
                        userUuid: state.userUuid,
                        popupUuid: state.popup.popupUuid
                    )

                    _ = try await increaseViewCount
                    await send(.setRelatedPopupList(try await relatedPopups))
                    await send(.setErrorMessage(nil))
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setLoading(false))
            }
        )
    }

    func toggleLike() -> AsyncStream<Reaction> {
        let popupUsecase = popupUsecase

        return .run { [state, popupUsecase] send in
            var popup = state.popup

            do {
                if popup.isFavorited {
                    try await popupUsecase.removeFavorite(userUuid: state.userUuid, popupUuid: popup.popupUuid)
                    popup.isFavorited = false
                    popup.favoriteCount = max(0, popup.favoriteCount - 1)
                } else {
                    try await popupUsecase.addFavorite(userUuid: state.userUuid, popupUuid: popup.popupUuid)
                    popup.isFavorited = true
                    popup.favoriteCount += 1
                }

                await send(.setPopup(popup))
                await send(.setErrorMessage(nil))
            } catch {
                await send(.setErrorMessage(error.localizedDescription))
            }
        }
    }

    func deactivatePopup() -> AsyncStream<Reaction> {
        let adminUsecase = adminUsecase

        return .concat(
            .just(.setDeactivating(true)),
            .run { [state, adminUsecase, onDeactivateComplete] send in
                do {
                    try await adminUsecase.deactivatePopup(popupUuid: state.popup.popupUuid)
                    await send(.setErrorMessage(nil))
                    await MainActor.run {
                        onDeactivateComplete()
                    }
                } catch {
                    await send(.setErrorMessage(error.localizedDescription))
                }

                await send(.setDeactivating(false))
            }
        )
    }

    func emptyReactionStream() -> AsyncStream<Reaction> {
        AsyncStream { continuation in
            continuation.finish()
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
