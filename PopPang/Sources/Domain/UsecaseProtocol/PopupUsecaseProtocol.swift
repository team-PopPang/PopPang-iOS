//
//  PopupUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

protocol PopupUsecaseProtocol {
    
    func getPopupList() async throws -> [Popup]
    
    func getFavoriteList(userUuid: String) async throws -> [Popup]
    
    func addFavorite(userUuid: String, popupUuid: String) async throws
    
    func removeFavorite(userUuid: String, popupUuid: String) async throws
}
