//
//  PopupRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

final class PopupRepositoryImpl: PopupRepositoryProtocol {
    func getPopupList() async throws -> [PopupDTO] {
        do {
            let response = try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPopupList,
                                                                                        decodeTo: [PopupDTO].self)
            return response
        } catch {
            throw error
        }
    }
    
    func getFavoriteList(userUuid: String) async throws -> [PopupDTO] {
        let response = try await NetworkProvider.shared.popupProvidder.asyncRequest(.getFavoriteList(userUuid: userUuid),
                                                                                    decodeTo: [PopupDTO].self)
        return response
    }
    
    func searchPopupList(searchText: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.searchPopupList(searchText: searchText),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await NetworkProvider.shared.popupProvidder.asyncRequestVoid(.addFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }
    
    func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await NetworkProvider.shared.popupProvidder.asyncRequestVoid(.removeFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }
}
