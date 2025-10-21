//
//  UserRepositoryProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation

enum UserRepositoryError: Error {
    case decodingError          // JSON 파싱 실패
    case unknown(Error)         // 알 수 없는 에러
}

// MARK: - 레포지토리에서는 에러를 처리하지 않고 에러를 변환해서 상위 계층에 던지자
extension UserRepositoryError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .decodingError:
            return "데이터를 불러올 수 없습니다"
        case .unknown(let error):
            return "알 수 없는 오류: \(error.localizedDescription)"
        }
    }
}

protocol UserRepositoryProtocol {
    
    /// 닉네임 중복 여부 확인
    /// - Parameter nickname: 닉네임
    /// - Returns: 중복유무 Bool 타입
    func checkNickname(nickname: String) async throws -> Bool
    
    
    /// 자동 로그인
    /// - Parameter uuid: 로컬에 저장된 UUID
    /// - Returns: User
    func autoLogin(userUuid: String) async throws -> UserDTO
    
    
    /// 추첰 카테고리 리스트 가져오기
    /// - Returns: [RecommandDTO]
    func getRecommandList() async throws -> [RecommendListDTO]
    
    
    /// 키워드 리스트 가져오기
    /// - Returns: [KeywordDTO]
    func getAlertKeywordList(userUuid: String) async throws -> [KeywordDTO]
    
    
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
}

