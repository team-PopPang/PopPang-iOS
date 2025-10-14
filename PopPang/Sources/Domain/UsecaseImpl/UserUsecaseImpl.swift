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
    
    func autoLogin(uuid: String) async throws -> User {
        try await userRepository.autoLogin(uuid: uuid).toModel()
    }
    
    func getRecommandList() async throws -> [Recommand] {
        try await userRepository.getRecommandList()
            .map { $0.toModel() }
    }
    
    /// 키워드 리스트 가져오기
    /// - Returns: [Keyword]
    func getAlertKeywordList(uuid: String) async throws -> [Keyword] {
        try await userRepository.getAlertKeywordList(uuid: uuid)
            .map { $0.toModel() }
    }
}

final class StubUserUsecaseImpl: UserUsecaseProtocol {
    func checkNickname(nickname: String) async throws -> Bool {
        return true
    }
    
    func autoLogin(uuid: String) async throws -> User {
        return User.adminUser
    }
    
    func getRecommandList() async throws -> [Recommand] {
        return [Recommand(id: 1, recommendName: "123")]
    }
    
    func getAlertKeywordList(uuid: String) async throws -> [Keyword] {
        return [Keyword(keyword: "키워드1")]
    }
}
