//
//  AuthUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import Foundation
import AuthenticationServices

enum AuthError: Error {
    case invalidCredential
    case invalidAuthCode
    case serverError(String)
}

protocol AppleLoginUsecaseProtocol {
 
    /// 애플로그인 후 유저 엔티티 반환
    /// ASAuthorization객체에서  ASAuthorizationAppleIDCredential를 추출하여
    /// 사용자 정보를 확인하고 `User` 객체를 생성
    ///
    /// - Parameter authorization: 애플 로그인 인증 요청 결과 객체
    /// - Returns: User
    /// - Throws: 토큰 검증 실패, 네트워크 오류 등 로그인 과정에서 발생한 오류
    func appleLogin(authorization: ASAuthorization) async throws -> User
}

