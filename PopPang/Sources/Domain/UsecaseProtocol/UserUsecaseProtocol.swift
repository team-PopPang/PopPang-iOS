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
    func autoLogin(userUuid: String) async throws -> User
    
    
    /// 추첰 카테고리 리스트 가져오기
    /// - Returns: [Recommand]
    func getRecommandList() async throws -> [RecommendList]
    
    
    /// 유저 삭제
    /// - Parameter userUuid: userUuid
    func hardDeleteUser(userUuid: String) async throws
    
    
    /// 키워드 리스트 가져오기
    /// - Returns: [Keyword]
    func getAlertKeywordList(userUuid: String) async throws -> [Keyword]
    
    
    /// 알림키워드 추가하기
    /// - Parameters:
    ///   - userUuid: 유저 고유값
    ///   - alertKeyword: 알림 키워드 고유값
    func addAlertKeyword(userUuid: String, alertKeyword: String) async throws
    
    
    /// 알림키워드 삭제하기
    /// - Parameters:
    ///   - userUuid: 유저 고유값
    ///   - alertKeyword: 알림 키워드 고유값
    func removeAlertKeyword(userUuid: String, alertKeyword: String) async throws
    
    /// 닉네임 수정
    /// - Parameters:
    ///   - userUuid: 유저 고유값
    ///   - newNickname: 변경할 닉네임
    func updateNickname(userUuid: String, newNickname: String) async throws
    
    /// FCM토큰 일치 확인
    /// - Parameter userUuid: userUuid
    /// - Parameter fcmToken: fcmToken
    /// - Returns: 일치하면 true
    func checkFcmToken(userUuid: String, fcmToken: String) async throws -> Bool
    
    /// FCM토큰 갱신
    /// - Parameters:
    /// - Parameter userUuid: userUuid
    /// - Parameter fcmToken: fcmToken
    func updateFcmToken(userUuid: String, fcmToken: String) async throws
}

