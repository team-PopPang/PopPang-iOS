//
//  AdminRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 12/18/25.
//

import Foundation

final class AdminRepositoryImpl: AdminRepositoryProtocol {
    // MARK: - Popup
    func deactivatePopup(userUuid: String, popupUuid: String) async throws {
        try await NetworkProvider.shared.adminProvider.asyncRequestVoid(.deactivatePopup(userUuid: userUuid, popupUuid: popupUuid))
    }
}
