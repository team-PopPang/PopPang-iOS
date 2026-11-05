public protocol PopupUsecaseProtocol {
    /// 팝업리스트를 가져옵니다
    func getPopupList() async throws -> [Popup]

    /// 다가올 팝업 리스트를 가져옵니다
    func getUpcomingPopupList() async throws -> [Popup]

    /// 진행 중인 팝업 리스트를 가져옵니다
    func getInProgressPopupList() async throws -> [Popup]

    /// 로그인한 사용자의 찜 리스트를 가져옵니다
    func getFavoriteList() async throws -> [Popup]

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
    func getPersonalSearchPopupList(searchText: String) async throws -> [Popup]

    /// 지역·구·정렬로 거른 팝업 목록을 반환합니다(V2). 찜 여부는 로그인한 사용자 기준입니다.
    func getFilteredPopupList(region: String, district: String, homeSortStandard: String) async throws -> [Popup]

    /// 로그인한 사용자의 랜덤 팝업 목록을 반환합니다(V2). 홈 추천에 씁니다.
    func getUserRandomPopupList() async throws -> [Popup]

    /// 로그인한 사용자의 오픈 예정 팝업 목록을 반환합니다(V2).
    func getUserUpcomingPopupList() async throws -> [Popup]

    /// 맵 팝업 필터 조회
    func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup]

    /// 상세 화면의 관련 팝업 조회 (V2, 사용자는 Access Token으로 정해짐)
    func getRelatedPopupList(popupUuid: String) async throws -> [Popup]

    /// 랜덤 팝업 10개를 반환합니다
    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup]

    /// 알림 팝업 리스트 가져오기
    func getAlertPopupList(userUuid: String) async throws -> [Popup]

    /// 알림 팝업 단건 지우기
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws

    /// 상세 화면의 팝업 하나를 조회합니다 (V2). 없는 팝업이면 `PopupError.notFound`를 던집니다.
    func getPopupDetail(popupUuid: String) async throws -> PopupDetail

    /// 팝업 조회수를 증가시킵니다
    func increaseViewCount(popupUuid: String) async throws

    /// 찜 리스트에 팝업을 추가합니다
    func addFavorite(userUuid: String, popupUuid: String) async throws

    /// 찜 리스트에서 팝업을 삭제합니다
    func removeFavorite(userUuid: String, popupUuid: String) async throws

    /// 로그인한 사용자의 찜 리스트에 팝업을 추가합니다
    func addFavorite(popupUuid: String) async throws

    /// 로그인한 사용자의 찜 리스트에서 팝업을 삭제합니다
    func removeFavorite(popupUuid: String) async throws

    /// 지역/구 목록을 가져옵니다
    func getRegionList() async throws -> [RegionList]

    /// 인기 카테고리를 가져옵니다
    func getPopularRecommendList() async throws -> [Recommend]

    /// 특정 카테고리 팝업 목록을 가져옵니다
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup]
}
