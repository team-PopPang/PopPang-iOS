//
//  RepositoryTest.swift
//  RepositoryTest
//
//  Created by 김동현 on 11/9/25.
//

import Testing
@testable import PopPang

struct UserRepositoryTest {
    private let userRepository: UserRepositoryProtocol
    
    init() {
        userRepository = UserRepositoryImpl()
    }
    
    @Test("[Get] User Test")
    func getUser() async throws {
        let fetchedUserInto = try await userRepository.autoLogin(userUuid: DummyData.userInfo.userUuid)
        #expect(fetchedUserInto.nickname == DummyData.userInfo.nickname)
    }
    
//    @Test("[Update] User FcmToken Test")
//    func updateUserFcmToken() async throws {
//        try await userRepository.updateFcmToken(userUuid: DummyData.userInfo.userUuid, fcmToken: "1234")
//        let fetchedUserInto = try await userRepository.autoLogin(userUuid: DummyData.userInfo.userUuid)
//        #expect(fetchedUserInto.fcmToken == "1234")
//    }
}
