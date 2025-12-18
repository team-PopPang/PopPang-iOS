//
//  AdminUsecaseImpl.swift
//  PopPang
//
//  Created by 김동현 on 12/18/25.
//

import Foundation

final class AdminUsecaseImpl: AdminUsecaseProtocol {

    private let adminRepository: AdminRepositoryProtocol
    
    init(adminRepository: AdminRepositoryProtocol) {
        self.adminRepository = adminRepository
    }
    
    func deactivatePopup(userUuid: String, popupUuid: String) async throws {
        try await adminRepository.deactivatePopup(userUuid: userUuid, popupUuid: popupUuid)
    }
}
