import Core
import Domain
import Foundation
import Moya

public final class PopupRepositoryImpl: PopupRepositoryProtocol {
    public init() {}

    public func getPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getUpcomingPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getUpcomingPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getInProgressPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getInProgressPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getFavoriteList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getFavoriteList(userUuid: userUuid), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func searchPopupList(searchText: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.searchPopupList(searchText: searchText), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getRandomPopupList() async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getRandomPopupList, decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getPersonalPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getPersonalPopupList(userUuid: userUuid), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalUseerRecommendPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalUpcomingPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalFilteredPopupList(
                userUuid: userUuid,
                region: region,
                district: district,
                homeSortStandard: homeSortStandard
            ),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalSearchPopupList(userUuid: userUuid, searchText: searchText),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalMapFilteredPopupList(
                userUuid: userUuid,
                region: region,
                district: district,
                latitude: latitude,
                longitude: longitude,
                mapSortStandard: mapSortStandard
            ),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalRelatedPopupList(userUuid: userUuid, popupUuid: popupUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPersonalRandomPopupList(userUuid: userUuid),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    public func getAlertPopupList(userUuid: String) async throws -> [Popup] {
        try await popupProvider.asyncRequest(.getAlertPopupList(userUuid: userUuid), decodeTo: [PopupDTO].self).map { $0.toEntity() }
    }

    public func removeAlertPopup(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.removeAlertPopup(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func increaseViewCount(popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.increaseViewCount(popupUuid: popupUuid))
    }

    public func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.addFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupProvider.asyncRequestVoid(.removeFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }

    public func getRegionList() async throws -> [RegionList] {
        try await popupProvider.asyncRequest(.getRegionList, decodeTo: [RegionListDTO].self).map { $0.toEntity() }
    }

    public func getPopularRecommendList() async throws -> [Recommend] {
        try await popupProvider.asyncRequest(.getPopularRecommendList, decodeTo: [RecommendListDTO].self).map { $0.toModel() }
    }

    public func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] {
        try await popupProvider.asyncRequest(
            .getPopularRecommendPopupList(userUuid: userUuid, recommendId: recommendId),
            decodeTo: [PopupDTO].self
        ).map { $0.toEntity() }
    }

    private var popupProvider: MoyaProvider<PopupAPI> {
        NetworkProvider.shared.makeProvider()
    }
}
