//
//  PopupRepositoryProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

protocol PopupRepositoryProtocol {
    
    // MARK: - Popup
    /// 팝업리스트를 가져옵니다
    /// - Returns: [PopupDTO]
    func getPopupList() async throws -> [PopupDTO]
    
    
    /// 다가올 팝업 리스트를 가져옵니다
    /// - Returns: [PopupDTO]
    func getUpcomingPopupList() async throws -> [PopupDTO]
    
    
    /// 진행 중인 팝업 리스트를 가져옵니다
    /// - Returns: [PopupDTO]
    func getInProgressPopupList() async throws -> [PopupDTO]
    
    
    /// 찜 리스트를 가져옵니다
    /// - Parameter userUuid:userUuid
    /// - Returns: [PopupDTO]
    func getFavoriteList(userUuid: String) async throws -> [PopupDTO]
    
    
    /// 팝업 검색 결과를 반환합니다
    /// - Parameter searchText: searchText
    /// - Returns: [PopupDTO]
    func searchPopupList(searchText: String) async throws -> [PopupDTO]
    
    
    /// 랜덤 팝업 10개 를 반환합니다
    /// - Returns: [PopupDTO]
    func getRandomPopupList() async throws -> [PopupDTO]
    
    
    // MARK: - 개인화 Popup
    /// 팝업리스트를 가져옵니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [PopupDTO]
    func getPersonalPopupList(userUuid: String) async throws -> [PopupDTO]
    
    
    /// 유저별 개인화 추천 팝업리스트를 가져옵니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [PopupDTO]
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [PopupDTO]
    
    
    /// 다가올 팝업 리스트를 가져옵니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [PopupDTO]
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [PopupDTO]
    
    
    /// 홈 화면용 팝업 필터 조회
    /// - Parameters:
    ///   - userUuid: 사용자 고유 ID
    ///   - region: 선택된 지역명 (예: "서울")
    ///   - district: 선택된 구 이름 (예: "강남구", "전체" 가능)
    ///   - homeSortStandard: 정렬 기준 (NEWEST / CLOSING_SOON / MOST_FAVORITED / MOST_VIEWED)
    /// - Returns: [PopupDTO]
    func getPersonalFilteredPopupList(userUuid: String,
                                      region: String,
                                      district: String,
                                      homeSortStandard: String) async throws -> [PopupDTO]
    
    /// 팝업 검색 결과를 반환합니다
    /// - Parameter userUuid: userUuid
    /// - Parameter searchText: searchText
    /// - Returns: [PopupDTO]
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [PopupDTO]

    
    /// 맵 팝업 필터 조회
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - region: 선택된 지역명 (예: "서울")
    ///   - district: 선택된 구 이름 (예: "강남구", "전체" 가능)
    ///   - latitude: 위도
    ///   - longitude: 경도
    ///   - mapSortStandard: 정렬 기준(CLOSEST / NEWEST / CLOSING_SOON / MOST_FAVORITED / MOST_VIEWED)
    func getPersonalMapFilteredPopupList(userUuid: String,
                                         region: String,
                                         district: String,
                                         latitude: Double?,
                                         longitude: Double?,
                                         mapSortStandard: String) async throws -> [PopupDTO]
    
    
    /// 유저별 연관 팝업 추천 조회 - depreceated
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - popupUuid: popupUuid
    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [PopupDTO]
    
    
    /// 랜덤 팝업 10개 를 반환합니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [PopupDTO]
    func getPersonalRandomPopupList(userUuid: String) async throws -> [PopupDTO]
    
    
    // MARK: - 알림 Popup
    /// 알림 팝업 리스트 가져오기
    /// - Parameter userUuid: 유저 고유값
    /// - Returns: [PopupDTO]
    func getAlertPopupList(userUuid: String) async throws -> [PopupDTO]
    
    
    /// 알림 팝업 단건 지우기
    /// - Parameters:
    ///   - userUuid: 유저 고유값
    ///   - popupUuid: 팝업 고유값
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws
    

    // MARK: - Favorite
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
    
    
    // MARK: - 지역/구
    /// 지역/구 목록을 가져옵니다
    /// - Returns: [RegionListDTO]
    func getRegionList() async throws -> [RegionListDTO]
    
    // MARK: - 추천
    /// 인기 카테고리를 가져옵니다
    /// - Returns: [RecommendListDTO]
    func getPopularRecommendList() async throws -> [RecommendListDTO]
    
    /// 특정 카테고리 팝업 목록을 가져옵니다
    /// - Returns: [PopupDTO]
    func getPopularRecommendPopupList(userUuid: String, recommendId: Int) async throws -> [PopupDTO]
}
