//
//  AppleLoginUsecase.swift
//  PopPang
//
//  Created by 김동현 on 9/23/25.
//

import Foundation
import AuthenticationServices

final class AppleAuthUsecaseImpl: AppleAuthUsecaseProtocol {
    
    private let appleAuthRepository: AppleAuthRepositoryProtocol
    
    init(appleAuthRepository: AppleAuthRepositoryProtocol) {
        self.appleAuthRepository = appleAuthRepository
    }
    
    func appleLogin(authorization: ASAuthorization) async throws -> User {
        try await appleAuthRepository.appleLogin(authorization: authorization)
    }
}

final class StubAppleAuthUsecaseImpl: AppleAuthUsecaseProtocol {
    
    func appleLogin(authorization: ASAuthorization) async throws -> User {
        
        // 서버에 authCode 전달
        let userDto = try await sendAuthCodeToServer(authCode: "code")
        return userDto.toModel()
    }
    
    private func sendAuthCodeToServer(authCode: String) async throws -> UserDTO {
        print("authCode: \(authCode)")
        return UserDTO(
            uid: "stub-uid-123",
            email: "stub@example.com",
            nickname: "김동현",
            //nickname: nil, // 닉네임 없음 → 신규가입 플로우로 유도
            role: "member",
            provider: "apple",
            keywords: [],
            recommands: []
        )
    }
}
