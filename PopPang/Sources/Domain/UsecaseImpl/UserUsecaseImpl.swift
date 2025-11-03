//
//  UserUsecaseImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation

final class UserUsecaseImpl: UserUsecaseProtocol {
    
    private let userRepository: UserRepositoryProtocol
    
    init(userRepository: UserRepositoryProtocol) {
        self.userRepository = userRepository
    }
    
    func checkNickname(nickname: String) async throws -> Bool {
        try await userRepository.checkNickname(nickname: nickname)
    }
    
    func autoLogin(userUuid: String) async throws -> User {
        try await userRepository.autoLogin(userUuid: userUuid).toModel()
    }
    
    func getRecommandList() async throws -> [RecommendList] {
        try await userRepository.getRecommandList()
            .map { $0.toModel() }
    }
    
    /// 키워드 리스트 가져오기
    /// - Returns: [Keyword]
    func getAlertKeywordList(userUuid: String) async throws -> [Keyword] {
        try await userRepository.getAlertKeywordList(userUuid: userUuid)
            .map { $0.toModel() }
    }
    
    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userRepository.addAlertKeyword(userUuid: userUuid, alertKeyword: alertKeyword)
    }
    
    
    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        try await userRepository.removeAlertKeyword(userUuid: userUuid, alertKeyword: alertKeyword)
    }
    
    func updateNickname(userUuid: String, newNickname: String) async throws {
        try await userRepository.updateNickname(userUuid: userUuid, newNickname: newNickname)
    }
    
    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        try await userRepository.checkFcmToken(userUuid: userUuid, fcmToken: fcmToken)
    }
    
    func updateFcmToken(userUuid: String, fcmToken: String) async throws {
        try await userRepository.updateFcmToken(userUuid: userUuid, fcmToken: fcmToken)
    }
}

final class StubUserUsecaseImpl: UserUsecaseProtocol {
    func checkNickname(nickname: String) async throws -> Bool {
        return true
    }
    
    func autoLogin(userUuid: String) async throws -> User {
        return User.adminUser
    }
    
    func getRecommandList() async throws -> [RecommendList] {
        return [RecommendList(id: 1, recommendName: "123")]
    }
    
    func getAlertKeywordList(userUuid: String) async throws -> [Keyword] {
        return [Keyword(keyword: "키워드1")]
    }
    
    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        
    }
        
    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws {
        
    }
    
    func updateNickname(userUuid: String, newNickname: String) async throws {
        
    }
    
    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool {
        return true
    }
    
    func updateFcmToken(userUuid: String, fcmToken: String) async throws {
        
    }
}
