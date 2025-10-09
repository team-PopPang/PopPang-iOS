//
//  KakaoAuthUsecaseImpl.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import Foundation

final class KakaoAuthUsecaseImpl: KakaoAuthUsecaseProtocol {
    private let kakaoAuthRepository: KakaoAuthRepositoryProtocol
    
    init(kakaoAuthRepository: KakaoAuthRepositoryProtocol) {
        self.kakaoAuthRepository = kakaoAuthRepository
    }
    
    func kakaoLogin() async throws -> User {
        try await kakaoAuthRepository.kakaoLogin().toModel()
    }
    
    func kakaoRegister(user: User) async throws -> User {
        try await kakaoAuthRepository.kakaoRegister(user: user).toModel()
    }
}

final class StubKakaoAuthUsecaseImpl: KakaoAuthUsecaseProtocol {
    func kakaoLogin() async throws -> User {
        return User.adminUser
    }
    
    func kakaoRegister(user: User) async throws -> User {
        return User.adminUser
    }
}
