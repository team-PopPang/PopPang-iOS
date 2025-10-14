//
//  UserUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation

protocol UserUsecaseProtocol {
    /// 닉네임 중복 여부 확인
    /// - Parameter nickname: 닉네임
    /// - Returns: 중복유무 Bool 타입
    func checkNickname(nickname: String) async throws -> Bool
    
    
    /// 자동 로그인
    /// - Parameter uuid: 로컬에 저장된 UUID
    /// - Returns: User
    func autoLogin(uuid: String) async throws -> User
    
    /// 추첰 카테고리 리스트 가져오기
    /// - Returns: [Recommand]
    func getRecommandList() async throws -> [Recommand]
    
    /// 키워드 리스트 가져오기
    /// - Returns: [Keyword]
    func getAlertKeywordList(uuid: String) async throws -> [Keyword]
}

