//
//  PopupUsecaseImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

final class PopupUsecaseImpl: PopupUsecaseProtocol {
    
    private let popupRepository: PopupRepositoryProtocol
    
    init(popupRepository: PopupRepositoryProtocol) {
        self.popupRepository = popupRepository
    }
    
    func getPopupList() async throws -> [Popup] {
        try await popupRepository.getPopupList()
            .map { $0.toEntity() }
    }
}
