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
}
