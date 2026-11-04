import ComposableArchitecture
import Domain
import Foundation
import Kingfisher

/// 팝업 상세 화면
///
/// `popupUuid`만 받아 열리고, 화면 내용은 단건 조회로 직접 불러온다 (스펙 D-6).
/// 목록 모델(`Popup`)에 묶이지 않아 상세 전용 데이터를 더하거나 SDUI로 바꾸기 쉽다.
@Reducer
public struct PopupDetailFeature {
    @ObservableState
    public struct State: Equatable, Sendable {
        public let popupUuid: String
        var detailState: DetailState = .loading
        var relatedPopupList: [Popup] = []
        var isDeactivating = false
        var didDeactivate = false
        var hasLoaded = false
        /// 조회 기록·관련 팝업·하트·비활성화 실패. 화면에는 보여 주지 않는다 (스펙 2차 답).
        var errorMessage: String?

        public init(popupUuid: String) {
            self.popupUuid = popupUuid
        }

        /// 불러온 상세 데이터. 받기 전이거나 실패했으면 `nil`이다.
        var detail: PopupDetail? {
            guard case .loaded(let detail) = detailState else { return nil }
            return detail
        }
    }

    public enum DetailState: Equatable, Sendable {
        case loading
        case loaded(PopupDetail)
        case failed(LoadFailure)
    }

    public enum LoadFailure: Equatable, Sendable {
        /// 없는 팝업이다 (404 4301). 다시 시도해도 같아서 뒤로 가기만 보여 준다.
        case notFound
        /// 서버 오류나 네트워크 문제다. 다시 시도를 보여 준다.
        case failed
    }

    public enum Action: Equatable, Sendable {
        case onAppear
        case retryTapped
        case detailLoaded(PopupDetail)
        case detailFailed(LoadFailure)
        case toggleLike
        case deactivatePopup
        case relatedPopupListLoaded([Popup])
        case favoriteUpdated(isFavorited: Bool, favoriteCount: Int)
        case deactivateCompleted
        case deactivatingChanged(Bool)
        case errorMessageChanged(String?)
        case delegate(Delegate)

        public enum Delegate: Equatable, Sendable {
            case favoriteChanged(popupUuid: String, isFavorited: Bool, favoriteCount: Int)
        }
    }

    @Dependency(\.popupDetailClient) private var popupDetailClient: PopupDetailClient

    private enum CancelID {
        case detail
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                guard state.hasLoaded == false else { return .none }
                state.hasLoaded = true
                state.detailState = .loading
                state.didDeactivate = false
                state.errorMessage = nil
                // 상세·조회 기록·관련 팝업은 따로 보낸다. 하나가 실패해도 나머지는 반영한다.
                return .merge(
                    loadDetail(popupUuid: state.popupUuid),
                    increaseViewCount(popupUuid: state.popupUuid),
                    loadRelatedPopups(popupUuid: state.popupUuid)
                )

            case .retryTapped:
                // 없는 팝업은 다시 시도해도 같다. 다시 시도는 상세 데이터만 다시 받는다.
                guard state.detailState == .failed(.failed) else { return .none }
                state.detailState = .loading
                return loadDetail(popupUuid: state.popupUuid)

            case .detailLoaded(let detail):
                state.detailState = .loaded(detail)
                let urls = detail.imageUrlList
                return .run { _ in prefetchImages(urls: urls) }

            case .detailFailed(let failure):
                state.detailState = .failed(failure)
                return .none

            case .toggleLike:
                // 하트는 불러온 뒤에만 누를 수 있다.
                guard var detail = state.detail else { return .none }
                let previousIsFavorited = detail.isFavorited
                let previousFavoriteCount = detail.favoriteCount
                let nextIsFavorited = !previousIsFavorited
                let nextFavoriteCount = nextIsFavorited
                    ? previousFavoriteCount + 1
                    : max(0, previousFavoriteCount - 1)

                detail.isFavorited = nextIsFavorited
                detail.favoriteCount = nextFavoriteCount
                state.detailState = .loaded(detail)

                return .merge(
                    .send(.delegate(.favoriteChanged(
                        popupUuid: detail.popupUuid,
                        isFavorited: nextIsFavorited,
                        favoriteCount: nextFavoriteCount
                    ))),
                    toggleLike(
                        popupUuid: detail.popupUuid,
                        wasFavorited: previousIsFavorited,
                        previousFavoriteCount: previousFavoriteCount
                    )
                )

            case .deactivatePopup:
                guard state.detail != nil else { return .none }
                state.isDeactivating = true
                state.errorMessage = nil
                return deactivatePopup(popupUuid: state.popupUuid)

            case .relatedPopupListLoaded(let popups):
                state.relatedPopupList = popups
                return .none

            case let .favoriteUpdated(isFavorited, favoriteCount):
                guard var detail = state.detail else { return .none }
                detail.isFavorited = isFavorited
                detail.favoriteCount = favoriteCount
                state.detailState = .loaded(detail)
                return .none

            case .deactivateCompleted:
                state.isDeactivating = false
                state.didDeactivate = true
                state.errorMessage = nil
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
    func loadDetail(popupUuid: String) -> Effect<Action> {
        .run { [popupDetailClient] send in
            do {
                let detail = try await popupDetailClient.getPopupDetail(popupUuid)
                await send(.detailLoaded(detail))
            } catch is CancellationError {
                return
            } catch {
                let failure: LoadFailure = (error as? PopupError) == .notFound ? .notFound : .failed
                await send(.detailFailed(failure))
            }
        }
        .cancellable(id: CancelID.detail, cancelInFlight: true)
    }

    func increaseViewCount(popupUuid: String) -> Effect<Action> {
        .run { [popupDetailClient] send in
            do {
                try await popupDetailClient.increaseViewCount(popupUuid)
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }
        }
    }

    func loadRelatedPopups(popupUuid: String) -> Effect<Action> {
        .run { [popupDetailClient] send in
            do {
                await send(.relatedPopupListLoaded(try await popupDetailClient.getRelatedPopupList(popupUuid)))
            } catch {
                await send(.errorMessageChanged(error.localizedDescription))
            }
        }
    }

    func toggleLike(
        popupUuid: String,
        wasFavorited: Bool,
        previousFavoriteCount: Int
    ) -> Effect<Action> {
        .run { [popupDetailClient] send in
            do {
                if wasFavorited {
                    try await popupDetailClient.removeFavorite(popupUuid)
                } else {
                    try await popupDetailClient.addFavorite(popupUuid)
                }

                await send(.errorMessageChanged(nil))
            } catch {
                // 실패하면 이전 값으로 되돌리고 목록에도 다시 알린다.
                await send(.favoriteUpdated(
                    isFavorited: wasFavorited,
                    favoriteCount: previousFavoriteCount
                ))
                await send(.delegate(.favoriteChanged(
                    popupUuid: popupUuid,
                    isFavorited: wasFavorited,
                    favoriteCount: previousFavoriteCount
                )))
                await send(.errorMessageChanged(error.localizedDescription))
            }
        }
    }

    func deactivatePopup(popupUuid: String) -> Effect<Action> {
        .run { [popupDetailClient] send in
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
