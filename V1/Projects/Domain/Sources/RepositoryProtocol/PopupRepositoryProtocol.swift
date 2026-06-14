public protocol PopupRepositoryProtocol {
    /// 팝업리스트를 가져옵니다
    /// - Returns: [Popup]
    func getPopupList() async throws -> [Popup]

    /// 다가올 팝업 리스트를 가져옵니다
    /// - Returns: [Popup]
    func getUpcomingPopupList() async throws -> [Popup]

    /// 진행 중인 팝업 리스트를 가져옵니다
    /// - Returns: [Popup]
    func getInProgressPopupList() async throws -> [Popup]

    /// 찜 리스트를 가져옵니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [Popup]
    func getFavoriteList(userUuid: String) async throws -> [Popup]

    /// 팝업 검색 결과를 반환합니다
    /// - Parameter searchText: searchText
    /// - Returns: [Popup]
    func searchPopupList(searchText: String) async throws -> [Popup]

    /// 랜덤 팝업 10개를 반환합니다
    /// - Returns: [Popup]
    func getRandomPopupList() async throws -> [Popup]

    /// 팝업리스트를 가져옵니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [Popup]
    func getPersonalPopupList(userUuid: String) async throws -> [Popup]

    /// 유저별 개인화 추천 팝업리스트를 가져옵니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [Popup]
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [Popup]

    /// 다가올 팝업 리스트를 가져옵니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [Popup]
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup]

    /// 홈 화면용 팝업 필터 조회
    /// - Parameters:
    ///   - userUuid: 사용자 고유 ID
    ///   - region: 선택된 지역명
    ///   - district: 선택된 구 이름
    ///   - homeSortStandard: 정렬 기준
    /// - Returns: [Popup]
    func getPersonalFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        homeSortStandard: String
    ) async throws -> [Popup]

    /// 팝업 검색 결과를 반환합니다
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - searchText: searchText
    /// - Returns: [Popup]
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup]

    /// 맵 팝업 필터 조회
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - region: 선택된 지역명
    ///   - district: 선택된 구 이름
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - mapSortStandard: 정렬 기준
    func getPersonalMapFilteredPopupList(
        userUuid: String,
        region: String,
        district: String,
        latitude: Double?,
        longitude: Double?,
        mapSortStandard: String
    ) async throws -> [Popup]

    /// 유저별 연관 팝업 추천 조회
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - popupUuid: popupUuid
    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [Popup]

    /// 랜덤 팝업 10개를 반환합니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [Popup]
    func getPersonalRandomPopupList(userUuid: String) async throws -> [Popup]

    /// 알림 팝업 리스트 가져오기
    /// - Parameter userUuid: 유저 고유값
    /// - Returns: [Popup]
    func getAlertPopupList(userUuid: String) async throws -> [Popup]

    /// 알림 팝업 단건 지우기
    /// - Parameters:
    ///   - userUuid: 유저 고유값
    ///   - popupUuid: 팝업 고유값
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws

    /// 팝업 조회수를 증가시킵니다
    /// - Parameter popupUuid: popupUuid
    func increaseViewCount(popupUuid: String) async throws

    /// 찜 리스트에 팝업을 추가합니다
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - popupUuid: popupUuid
    func addFavorite(userUuid: String, popupUuid: String) async throws

    /// 찜 리스트에서 팝업을 삭제합니다
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - popupUuid: popupUuid
    func removeFavorite(userUuid: String, popupUuid: String) async throws

    /// 지역/구 목록을 가져옵니다
    /// - Returns: [RegionList]
    func getRegionList() async throws -> [RegionList]

    /// 인기 카테고리를 가져옵니다
    /// - Returns: [Recommend]
    func getPopularRecommendList() async throws -> [Recommend]

    /// 특정 카테고리 팝업 목록을 가져옵니다
    /// - Returns: [Popup]
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [Popup]
}
