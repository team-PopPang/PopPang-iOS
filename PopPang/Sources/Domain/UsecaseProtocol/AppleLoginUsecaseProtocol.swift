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
    /// Apple 로그인 -> auth code 반환
    func appleLogin(authorization: ASAuthorization) async throws -> User
}

