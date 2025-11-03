//
//  PopupUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

protocol PopupUsecaseProtocol {
    
    func getPopupList() async throws -> [Popup]
    
    func getUpcomingPopupList() async throws -> [Popup]

    func getInProgressPopupList() async throws -> [Popup]
    
    func getFavoriteList(userUuid: String) async throws -> [Popup]
    
    func searchPopupList(searchText: String) async throws -> [Popup]
    
    func increaseViewCount(popupUuid: String) async throws
    
    func addFavorite(userUuid: String, popupUuid: String) async throws
    
    func removeFavorite(userUuid: String, popupUuid: String) async throws
    
    func getRegionList() async throws -> [RegionList]
}
