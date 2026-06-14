public final class PopupUsecaseImpl: PopupUsecaseProtocol {
    private let popupRepository: PopupRepositoryProtocol

    public init(popupRepository: PopupRepositoryProtocol) {
        self.popupRepository = popupRepository
    }

    public func getPopupList() async throws -> [Popup] {
        try await popupRepository.getPopupList()
    }

    public func getUpcomingPopupList() async throws -> [Popup] {
        try await popupRepository.getUpcomingPopupList()
    }

    public func getInProgressPopupList() async throws -> [Popup] {
        try await popupRepository.getInProgressPopupList()
    }

    public func getFavoriteList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getFavoriteList(userUuid: userUuid)
    }

    public func searchPopupList(searchText: String) async throws -> [Popup] {
        try await popupRepository.searchPopupList(searchText: searchText)
    }

    public func getRandomPopupList() async throws -> [Popup] {
        try await popupRepository.getRandomPopupList()
    }

    public func getPersonalPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalPopupList(userUuid: userUuid)
    }

    public func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalUseerRecommendPopupList(userUuid: userUuid)
    }

    public func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalUpcomingPopupList(userUuid: userUuid)
    }

    public func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup] {
        try await popupRepository.getPersonalFilteredPopupList(
            userUuid: userUuid,
            region: region,
            district: district,
            homeSortStandard: homeSortStandard
        )
    }

    public func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] {
        try await popupRepository.getPersonalSearchPopupList(
            userUuid: userUuid,
            searchText: searchText
        )
    }

    public func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup] {
        try await popupRepository.getPersonalMapFilteredPopupList(
            userUuid: userUuid,
            region: region,
            district: district,
            latitude: latitude,
            longitude: longitude,
            mapSortStandard: mapSortStandard
        )
    }

    public func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalRelatedPopupList(
            userUuid: userUuid,
            popupUuid: popupUuid
        )
    }

    public func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalRandomPopupList(userUuid: userUuid)
    }

    public func getAlertPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getAlertPopupList(userUuid: userUuid)
    }

    public func removeAlertPopup(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.removeAlertPopup(userUuid: userUuid, popupUuid: popupUuid)
    }

    public func increaseViewCount(popupUuid: String) async throws {
        try await popupRepository.increaseViewCount(popupUuid: popupUuid)
    }

    public func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
    }

    public func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
    }

    public func getRegionList() async throws -> [RegionList] {
        try await popupRepository.getRegionList()
    }

    public func getPopularRecommendList() async throws -> [Recommend] {
        try await popupRepository.getPopularRecommendList()
    }

    public func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup] {
        try await popupRepository.getPopularRecommendPopupList(
            userUuid: userUuid,
            recommendId: recommendId
        )
    }
}
