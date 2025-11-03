//
//  PopupRepositoryProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

protocol PopupRepositoryProtocol {
    
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
    /// - Returns: [RegionListDTO]
    func getRegionList() async throws -> [RegionListDTO]
}
