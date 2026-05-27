public protocol PopupUsecaseProtocol {
    /// 팝업리스트를 가져옵니다
    func getPopupList() async throws -> [Popup]

    /// 다가올 팝업 리스트를 가져옵니다
    func getUpcomingPopupList() async throws -> [Popup]

    /// 진행 중인 팝업 리스트를 가져옵니다
    func getInProgressPopupList() async throws -> [Popup]

    /// 찜 리스트를 가져옵니다
    func getFavoriteList(userUuid: String) async throws -> [Popup]

    /// 팝업 검색 결과를 반환합니다
    func searchPopupList(searchText: String) async throws -> [Popup]

    /// 랜덤 팝업 10개를 반환합니다
    func getRandomPopupList() async throws -> [Popup]

    /// 팝업리스트를 가져옵니다
    func getPersonalPopupList(userUuid: String) async throws -> [Popup]

    /// 유저별 개인화 추천 팝업리스트를 가져옵니다
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup]

    /// 다가올 팝업 리스트를 가져옵니다
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup]

    /// 홈 화면용 팝업 필터 조회
    func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup]

    /// 팝업 검색 결과를 반환합니다
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup]

    /// 맵 팝업 필터 조회
    func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup]

    /// 유저별 연관 팝업 추천 조회
    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup]

    /// 랜덤 팝업 10개를 반환합니다
    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup]

    /// 알림 팝업 리스트 가져오기
    func getAlertPopupList(userUuid: String) async throws -> [Popup]

    /// 알림 팝업 단건 지우기
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws

    /// 팝업 조회수를 증가시킵니다
    func increaseViewCount(popupUuid: String) async throws

    /// 찜 리스트에 팝업을 추가합니다
    func addFavorite(userUuid: String, popupUuid: String) async throws

    /// 찜 리스트에서 팝업을 삭제합니다
    func removeFavorite(userUuid: String, popupUuid: String) async throws

    /// 지역/구 목록을 가져옵니다
    func getRegionList() async throws -> [RegionList]

    /// 인기 카테고리를 가져옵니다
    func getPopularRecommendList() async throws -> [Recommend]

    /// 특정 카테고리 팝업 목록을 가져옵니다
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup]
}
