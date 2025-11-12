//
//  PopupUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

protocol PopupUsecaseProtocol {
    
    // MARK: - Popup
    func getPopupList() async throws -> [Popup]
    
    func getUpcomingPopupList() async throws -> [Popup]

    func getInProgressPopupList() async throws -> [Popup]
    
    func getFavoriteList(userUuid: String) async throws -> [Popup]
    
    func searchPopupList(searchText: String) async throws -> [Popup]
    
    
    
    // MARK: - 개인화 Popup
    func getPersonalPopupList(userUuid: String) async throws -> [Popup]
    
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup]
    
    func getPersonalFilteredPopupList(userUuid: String, region: String, district: String, homeSortStandard: String) async throws -> [Popup]
    
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup]
    
    // MARK: - Favorite
    func increaseViewCount(popupUuid: String) async throws
    
    func addFavorite(userUuid: String, popupUuid: String) async throws
    
    func removeFavorite(userUuid: String, popupUuid: String) async throws
    
    // MARK: - 지역/구
    func getRegionList() async throws -> [RegionList]
}
