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
    
    
    /// 찜 리스트를 가져옵니다
    /// - Parameter userUuid:userUuid
    /// - Returns: [PopupDTO]
    func getFavoriteList(userUuid: String) async throws -> [PopupDTO]
    
    
    /// 팝업 검색 결과를 반환합니다
    /// - Parameter searchText: searchText
    /// - Returns: [PopupDTO]
    func searchPopupList(searchText: String) async throws -> [PopupDTO]
    
    
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
}
