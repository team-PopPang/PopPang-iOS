//
//  GoogleAuthUsecaseImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation

final class GoogleAuthUsecaseImpl: GoogleAuthUsecaseProtocol {
    
    private let googleAuthRepository: GoogleAuthRepositoryProtocol
    
    init(googleAuthRepository: GoogleAuthRepositoryProtocol) {
        self.googleAuthRepository = googleAuthRepository
    }
    
    func googleLogin() async throws -> User {
        try await googleAuthRepository.googleLogin()
    }
    
    func googleRegister(user: User) async throws -> User {
        try await googleAuthRepository.googleRegister(user: user)
    }
}
