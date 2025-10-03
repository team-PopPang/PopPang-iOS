//
//  UserRepositoryProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation

protocol UserRepositoryProtocol {
    
    /// 닉네임 중복 여부 확인
    /// - Parameter nickname: 닉네임
    /// - Returns: 중복유무 Bool 타입
    func checkNickname(nickname: String) async throws -> Bool
    
    
    /// 자동 로그인
    /// - Parameter uid: 로컬에 저장된 UID
    /// - Returns: User
    func autoLogin(uid: String) async throws -> User
}

