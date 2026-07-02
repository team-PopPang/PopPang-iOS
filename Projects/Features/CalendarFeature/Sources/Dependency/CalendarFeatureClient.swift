import ComposableArchitecture
import Domain

public struct CalendarFeatureClient: Sendable {
    public var getRegionList: @Sendable () async throws -> [RegionList]
    public var getPersonalFilteredPopupList: @Sendable (
        _ userUuid: String,
        _ region: String,
        _ district: String,
        _ homeSortStandard: String
    ) async throws -> [Popup]
    public var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    public var removeFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void

    public init(
        getRegionList: @escaping @Sendable () async throws -> [RegionList],
        getPersonalFilteredPopupList: @escaping @Sendable (
            _ userUuid: String,
            _ region: String,
            _ district: String,
            _ homeSortStandard: String
        ) async throws -> [Popup],
        addFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void,
        removeFavorite: @escaping @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    ) {
        self.getRegionList = getRegionList
        self.getPersonalFilteredPopupList = getPersonalFilteredPopupList
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
            getPersonalFilteredPopupList: { userUuid, region, district, homeSortStandard in
                try await popupUsecaseBox.usecase.getPersonalFilteredPopupList(
                    userUuid: userUuid,
                    region: region,
                    district: district,
                    homeSortStandard: homeSortStandard
                )
            },
            addFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            removeFavorite: { userUuid, popupUuid in
                try await popupUsecaseBox.usecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
            }
        )
    }
}

extension CalendarFeatureClient: DependencyKey {
    public static let liveValue = Self(
        getRegionList: { [] },
        getPersonalFilteredPopupList: { _, _, _, _ in [] },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in }
    )
}

extension CalendarFeatureClient: TestDependencyKey {
    public static let testValue = Self(
        getRegionList: { [] },
        getPersonalFilteredPopupList: { _, _, _, _ in [] },
        addFavorite: { _, _ in },
        removeFavorite: { _, _ in }
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
