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
    
    
    // MARK: - 개인화 Popup
    /// 팝업리스트를 가져옵니다
    /// - Parameter userUuid: userUuid
    /// - Returns: [PopupDTO]
    func getPersonalPopupList(userUuid: String) async throws -> [PopupDTO]
    
    
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
}
