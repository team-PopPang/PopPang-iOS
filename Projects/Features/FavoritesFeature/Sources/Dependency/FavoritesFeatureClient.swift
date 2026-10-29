import ComposableArchitecture
import Domain

public struct FavoritesFeatureClient: Sendable {
    public var getFavoriteList: @Sendable () async throws -> [Popup]
    /// 찜 탭의 팝업은 모두 찜한 팝업이라 하트는 해제만 한다.
    public var removeFavorite: @Sendable (_ popupUuid: String) async throws -> Void

    public init(
        getFavoriteList: @escaping @Sendable () async throws -> [Popup],
        removeFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void
    ) {
        self.getFavoriteList = getFavoriteList
        self.removeFavorite = removeFavorite
    }

    public static func live(
        popupUsecase: PopupUsecaseProtocol
    ) -> Self {
        let popupUsecaseBox = PopupUsecaseBox(popupUsecase)

        return Self(
            getFavoriteList: {
                try await popupUsecaseBox.usecase.getFavoriteList()
            },
            removeFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(popupUuid: popupUuid)
            }
        )
    }
}

extension FavoritesFeatureClient: DependencyKey {
    public static let liveValue = Self(
        getFavoriteList: { [] },
        removeFavorite: { _ in }
    )
}

extension FavoritesFeatureClient: TestDependencyKey {
    public static let testValue = Self(
        getFavoriteList: { [] },
        removeFavorite: { _ in }
    )
}

extension DependencyValues {
    public var favoritesFeatureClient: FavoritesFeatureClient {
        get { self[FavoritesFeatureClient.self] }
        set { self[FavoritesFeatureClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}
