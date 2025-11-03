//
//  PopupDetailViewModel.swift
//  PopPang
//
//  Created by 김동현 on 11/1/25.
//

import Foundation

final class PopupDetailViewModel: ObservableObject {
    @Dependency var popupUsecase: PopupUsecaseProtocol
}

extension PopupDetailViewModel {
    
    // 조회수 증가 요청
    func increaseViewCount(popupUuid: String) async {
        do {
            try await popupUsecase.increaseViewCount(popupUuid: popupUuid)
        } catch {
            print("❌ 조회수 증가 오류: \(error)")
        }
    }
}
