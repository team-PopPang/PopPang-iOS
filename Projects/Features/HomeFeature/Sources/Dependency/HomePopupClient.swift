import ComposableArchitecture
import Domain
import Foundation

struct HomePopupClient: Sendable {
    var getRegionList: @Sendable () async throws -> [RegionList]
    var getPersonalRandomPopupList: @Sendable (_ userUuid: String) async throws -> [Popup]
    var getPersonalUpcomingPopupList: @Sendable (_ userUuid: String) async throws -> [Popup]
    var getPersonalFilteredPopupList: @Sendable (
        _ userUuid: String,
        _ region: String,
        _ district: String,
        _ homeSortStandard: String
    ) async throws -> [Popup]
    var addFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
    var removeFavorite: @Sendable (_ userUuid: String, _ popupUuid: String) async throws -> Void
}

extension HomePopupClient: DependencyKey {
    static var liveValue: HomePopupClient {
        let box = PopupUsecaseBox(DIContainer.shared.resolve(PopupUsecaseProtocol.self))

        return HomePopupClient(
            getRegionList: {
                try await box.usecase.getRegionList()
            },
            getPersonalRandomPopupList: { userUuid in
                try await box.usecase.getPersonalRandomPopupList(userUuid: userUuid)
            },
            getPersonalUpcomingPopupList: { userUuid in
                try await box.usecase.getPersonalUpcomingPopupList(userUuid: userUuid)
            },
            getPersonalFilteredPopupList: { userUuid, region, district, homeSortStandard in
                try await box.usecase.getPersonalFilteredPopupList(
                    userUuid: userUuid,
                    region: region,
                    district: district,
                    homeSortStandard: homeSortStandard
                )
            },
            addFavorite: { userUuid, popupUuid in
                try await box.usecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
            },
            removeFavorite: { userUuid, popupUuid in
                try await box.usecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
            }
        )
    }
}

extension DependencyValues {
    var homePopupClient: HomePopupClient {
        get { self[HomePopupClient.self] }
        set { self[HomePopupClient.self] = newValue }
    }
}

private final class PopupUsecaseBox: @unchecked Sendable {
    let usecase: PopupUsecaseProtocol

    init(_ usecase: PopupUsecaseProtocol) {
        self.usecase = usecase
    }
}
