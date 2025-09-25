//
//  AppleAuthRepositoryProtocol.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import Foundation
import AuthenticationServices

protocol AppleAuthRepositoryProtocol {
    
    /// 애플 로그인
    /// - Parameter authorization: authCode를 PopPang 서버로 보낸 후 유저 정보를 받습니다
    /// - Returns: User
    func appleLogin(authorization: ASAuthorization) async throws -> User
}
