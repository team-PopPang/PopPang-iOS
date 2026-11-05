import ComposableArchitecture
import Domain

/// 달력 화면이 쓰는 서버 요청. 모두 V2라 Access Token의 사용자를 기준으로 하고 `userUuid`를 받지 않는다.
public struct CalendarFeatureClient: Sendable {
    public var getRegionList: @Sendable () async throws -> [RegionList]
    public var getFilteredPopupList: @Sendable (
        _ region: String,
        _ district: String,
        _ homeSortStandard: String
    ) async throws -> [Popup]
    public var addFavorite: @Sendable (_ popupUuid: String) async throws -> Void
    public var removeFavorite: @Sendable (_ popupUuid: String) async throws -> Void

    public init(
        getRegionList: @escaping @Sendable () async throws -> [RegionList],
        getFilteredPopupList: @escaping @Sendable (
            _ region: String,
            _ district: String,
            _ homeSortStandard: String
        ) async throws -> [Popup],
        addFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ popupUuid: String) async throws -> Void
    ) {
        self.getRegionList = getRegionList
        self.getFilteredPopupList = getFilteredPopupList
        self.addFavorite = addFavorite
        self.removeFavorite = removeFavorite
    }

    public static func live(
        popupUsecase: PopupUsecaseProtocol
    ) -> Self {
        let popupUsecaseBox = PopupUsecaseBox(popupUsecase)

        return Self(
            getRegionList: {
                try await popupUsecaseBox.usecase.getRegionList()
            },
            getFilteredPopupList: { region, district, homeSortStandard in
                try await popupUsecaseBox.usecase.getFilteredPopupList(
                    region: region,
                    district: district,
                    homeSortStandard: homeSortStandard
                )
            },
            addFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(popupUuid: popupUuid)
            },
            removeFavorite: { popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(popupUuid: popupUuid)
            }
        )
    }
}

extension CalendarFeatureClient: DependencyKey {
    public static let liveValue = Self(
        getRegionList: { [] },
        getFilteredPopupList: { _, _, _ in [] },
        addFavorite: { _ in },
        removeFavorite: { _ in }
    )
}

extension CalendarFeatureClient: TestDependencyKey {
    public static let testValue = Self(
        getRegionList: { [] },
        getFilteredPopupList: { _, _, _ in [] },
        addFavorite: { _ in },
        removeFavorite: { _ in }
    )
}

extension DependencyValues {
    public var calendarFeatureClient: CalendarFeatureClient {
        get { self[CalendarFeatureClient.self] }
        set { self[CalendarFeatureClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}
