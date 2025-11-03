//
//  PopupUsecaseImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

final class PopupUsecaseImpl: PopupUsecaseProtocol {
    
    private let popupRepository: PopupRepositoryProtocol
    
    init(popupRepository: PopupRepositoryProtocol) {
        self.popupRepository = popupRepository
    }
    
    func getPopupList() async throws -> [Popup] {
        try await popupRepository.getPopupList()
            .map { $0.toEntity() }
    }
    
    func getUpcomingPopupList() async throws -> [Popup] {
        try await popupRepository.getUpcomingPopupList()
            .map { $0.toEntity() }
    }
    
    func getInProgressPopupList() async throws -> [Popup] {
        try await popupRepository.getInProgressPopupList()
            .map { $0.toEntity() }
    }
    
    func getFavoriteList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getFavoriteList(userUuid: userUuid)
            .map { $0.toEntity() }
    }
    
    func searchPopupList(searchText: String) async throws -> [Popup] {
        try await popupRepository.searchPopupList(searchText: searchText)
            .map { $0.toEntity() }
    }
    
    func increaseViewCount(popupUuid: String) async throws {
        try await popupRepository.increaseViewCount(popupUuid: popupUuid)
    }
    
    func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
    }
    
    func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
    }
    
    func getRegionList() async throws -> [RegionList] {
        try await popupRepository.getRegionList()
            .map { $0.toEntity() }
    }
}
