//
//  PopupRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

final class PopupRepositoryImpl: PopupRepositoryProtocol {
    
    // MARK: - Popup
    func getPopupList() async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPopupList,
                                                                               decodeTo: [PopupDTO].self)
    }
    
    func getUpcomingPopupList() async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getUpcomingPopupList,
                                                                                    decodeTo: [PopupDTO].self)
    }
    
    func getFavoriteList(userUuid: String) async throws -> [PopupDTO] {
        let response = try await NetworkProvider.shared.popupProvidder.asyncRequest(.getFavoriteList(userUuid: userUuid),
                                                                                    decodeTo: [PopupDTO].self)
        return response
    }
    
    func getInProgressPopupList() async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getInProgressPopupList,
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func searchPopupList(searchText: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.searchPopupList(searchText: searchText),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func getRandomPopupList() async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getRandomPopupList, decodeTo: [PopupDTO].self)
    }
    
    // MARK: - 개인화 Popup
    func getPersonalPopupList(userUuid: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPersonalPopupList(userUuid: userUuid),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func getPersonalUseerRecommendPopupList(userUuid: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPersonalUseerRecommendPopupList(userUuid: userUuid),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func getPersonalUpcomingPopupList(userUuid: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPersonalUpcomingPopupList(userUuid: userUuid),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func getPersonalFilteredPopupList(userUuid: String, region: String, district: String, homeSortStandard: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPersonalFilteredPopupList(userUuid: userUuid,
                                                                                                   region: region,
                                                                                                   district: district,
                                                                                                   homeSortStandard: homeSortStandard), decodeTo: [PopupDTO].self)
    }
    
    func getPersonalSearchPopupList(userUuid: String, searchText: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPersonalSearchPopupList(userUuid: userUuid, searchText: searchText),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func getPersonalMapFilteredPopupList(userUuid: String,
                                         region: String,
                                         district: String,
                                         latitude: Double?,
                                         longitude: Double?,
                                         mapSortStandard: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPersonalMapFilteredPopupList(userUuid: userUuid,
                                                                                                      region: region,
                                                                                                      district: district,
                                                                                                      latitude: latitude,
                                                                                                      longitude: longitude,
                                                                                                      mapSortStandard: mapSortStandard),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func getPersonalRelatedPopupList(userUuid: String, popupUuid: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPersonalRelatedPopupList(userUuid: userUuid,
                                                                                                  popupUuid: popupUuid),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    func getPersonalRandomPopupList(userUuid: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPersonalRandomPopupList(userUuid: userUuid), decodeTo: [PopupDTO].self)
    }
    
    // MARK: - 알림 Popup
    func getAlertPopupList(userUuid: String) async throws -> [PopupDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getAlertPopupList(userUuid: userUuid),
                                                                     decodeTo: [PopupDTO].self)
    }
    
    
    /// 알림 팝업 단건 지우기
    func removeAlertPopup(userUuid: String, popupUuid: String) async throws {
        try await NetworkProvider.shared.popupProvidder.asyncRequestVoid(.removeAlertPopup(userUuid: userUuid,
                                                                                       popupUuid: popupUuid))
    }
    
    // MARK: - Favorite
    func increaseViewCount(popupUuid: String) async throws {
        try await NetworkProvider.shared.popupProvidder.asyncRequestVoid(.increaseViewCount(popupUuid: popupUuid))
    }
    
    func addFavorite(userUuid: String, popupUuid: String) async throws {
        try await NetworkProvider.shared.popupProvidder.asyncRequestVoid(.addFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }
    
    func removeFavorite(userUuid: String, popupUuid: String) async throws {
        try await NetworkProvider.shared.popupProvidder.asyncRequestVoid(.removeFavorite(userUuid: userUuid, popupUuid: popupUuid))
    }
    
    // MARK: - 지역/구
    func getRegionList() async throws -> [RegionListDTO] {
        try await NetworkProvider.shared.popupProvidder.asyncRequest(.getRegionList, decodeTo: [RegionListDTO].self)
    }
}
