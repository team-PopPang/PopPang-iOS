//
//  RepositoryTest.swift
//  RepositoryTest
//
//  Created by 김동현 on 11/9/25.
//

import Testing
@testable import PopPang

/*
struct RepositoryTest {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
    }

}
*/

struct UserRepositoryTest {
    private let userRepository: UserRepositoryProtocol
    
    init() {
        userRepository = UserRepositoryImpl()
    }
    
    @Test("User Fetch Test")
    func getUser() async throws {
        let fetchedUserInto = try await userRepository.autoLogin(userUuid: DummyData.userInfo.userUuid)
        #expect(fetchedUserInto.nickname == DummyData.userInfo.nickname)
    }
    
    @Test("User FcmToken Update Test")
    func updateUserFcmToken() async throws {
        try await userRepository.updateFcmToken(userUuid: DummyData.userInfo.userUuid, fcmToken: "1234")
        let fetchedUserInto = try await userRepository.autoLogin(userUuid: DummyData.userInfo.userUuid)
        #expect(fetchedUserInto.fcmToken == "1234")
    }
    
    /*
    @Test("User Nickname Update Test")
    func updateUserNickname() async throws {
        try await userRepository.updateNickname(userUuid: DummyData.userInfo.userUuid, newNickname: "테스터")
        let fetchedUserInto = try await userRepository.autoLogin(userUuid: DummyData.userInfo.userUuid)
        #expect(fetchedUserInto.nickname == "테스터")
    }
     */
}
