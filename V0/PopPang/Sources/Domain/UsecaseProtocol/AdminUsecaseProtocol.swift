//
//  AdminUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 12/18/25.
//

import Foundation

protocol AdminUsecaseProtocol {
    
    /// 관리자 팝업 비활성화
    /// - Parameters:
    ///   - userUuid: userUuid
    ///   - popupUuid: popupUuid
    func deactivatePopup(userUuid: String, popupUuid: String) async throws
}
