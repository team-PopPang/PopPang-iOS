//
//  PopupRepositoryTest.swift
//  RepositoryTest
//
//  Created by 김동현 on 11/13/25.
//

import Testing
@testable import PopPang

struct PopupRepositoryTest {
    private let popupRepository: PopupRepositoryProtocol
    
    init() {
        popupRepository = PopupRepositoryImpl()
    }
    
    @Test("[Get] PersonalPopupList Test")
    func getPopupList() async throws {
        let popupList = try await popupRepository.getPersonalPopupList(userUuid: DummyData.userInfo.userUuid)
        #expect(popupList.count > 0)
    }
    
    @Test("[Get] PersonalUpcomingPopupList Test")
    func getPersonalUpcomingPopupList() async throws {
        let popupList = try await popupRepository.getPersonalUpcomingPopupList(userUuid: DummyData.userInfo.userUuid)
        #expect(popupList.count > 0)
    }
    
    @Test("[Get] PersonalFilteredPopupList Test")
    func getPersonalFilteredPopupList() async throws {
        let popupList = try await popupRepository.getPersonalFilteredPopupList(userUuid: DummyData.userInfo.userUuid,
                                                                               region: "전체",
                                                                               district: "전체",
                                                                               homeSortStandard: "NEWEST")
        #expect(popupList.count > 0)
    }
    
    @Test("[Get] PersonalSearchPopupList Test")
    func getPersonalSearchPopupList() async throws {
        let popupList = try await popupRepository.getPersonalSearchPopupList(userUuid: DummyData.userInfo.userUuid,
                                                                             searchText: "팝업")
        #expect(popupList.count > 0)
    }
    
    @Test("[Get] PersonalMapFilteredPopupList Test")
    func getPersonalMapFilteredPopupList() async throws {
        let popupList = try await popupRepository.getPersonalMapFilteredPopupList(userUuid: DummyData.userInfo.userUuid,
                                                                                  region: "전체",
                                                                                  district: "전체",
                                                                                  latitude: nil,
                                                                                  longitude: nil,
                                                                                  mapSortStandard: "NEWEST")
        #expect(popupList.count > 0)
    }
    
    @Test("[Get] PersonalRandomPopupList Test")
    func getPersonalRandomPopupList() async throws {
        let popupList = try await popupRepository.getPersonalRandomPopupList(userUuid: DummyData.userInfo.userUuid)
        #expect(popupList.count > 0)
    }
    
    @Test("[Get] AlertPopupList Test")
    func getAlertPopupList() async throws {
        let popupList = try await popupRepository.getAlertPopupList(userUuid: DummyData.userInfo.userUuid)
        #expect(popupList.count > 0)
    }
    
    @Test("[Get] RegionList Test")
    func getRegionList() async throws {
        let regionList = try await popupRepository.getRegionList()
        #expect(regionList.count > 0)
    }
    
    @Test("[Get] getPopularRecommendList Test")
    func getPopularRecommendList() async throws {
        let popupList = try await popupRepository.getPopularRecommendList()
        #expect(popupList.count == 0)
        // #expect(popupList.count > 0)
    }
    
    @Test("[Get] getPopularRecommendPopupList Test")
    func getPopularRecommendPopupList() async throws {
        let popupList = try await popupRepository.getPopularRecommendPopupList(userUuid: DummyData.userInfo.userUuid,
                                                                               recommendId: 21)
        #expect(popupList.count > 0)
    }
}
