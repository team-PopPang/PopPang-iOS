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
    
    // MARK: - Popup
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
    
    // MARK: - 개인화 Popup
    func getPersonalPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalPopupList(userUuid: userUuid)
            .map { $0.toEntity() }
    }
    
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [Popup] {
        try await popupRepository.getPersonalUpcomingPopupList(userUuid: userUuid)
            .map { $0.toEntity() }
    }
    
    func getPersonalFilteredPopupList(userUuid: String, region: String, district: String, homeSortStandard: String) async throws -> [Popup] {
        try await popupRepository.getPersonalFilteredPopupList(userUuid: userUuid, region: region, district: district, homeSortStandard: homeSortStandard)
            .map { $0.toEntity() }
    }
    
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [Popup] {
        try await popupRepository.getPersonalSearchPopupList(userUuid: userUuid, searchText: searchText)
            .map { $0.toEntity() }
    }
    
    func getPersonalMapFilteredPopupList(userUuid: String,
                                         region: String,
                                         district: String,
                                         latitude: Double?,
                                         longitude: Double?,
                                         mapSortStandard: String) async throws -> [Popup] {
        try await popupRepository.getPersonalMapFilteredPopupList(userUuid: userUuid,
                                                                  region: region,
                                                                  district: district,
                                                                  latitude: latitude,
                                                                  longitude: longitude,
                                                                  mapSortStandard: mapSortStandard)
        .map { $0.toEntity() }
    }
    
    // MARK: - Favorite
    func increaseViewCount(popupUuid: String) async throws {
        try await popupRepository.increaseViewCount(popupUuid: popupUuid)
    }
    
    func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
    }
    
    func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await popupRepository.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
    }
    
    // MARK: - 지역/구
    func getRegionList() async throws -> [RegionList] {
        try await popupRepository.getRegionList()
            .map { $0.toEntity() }
    }
}
