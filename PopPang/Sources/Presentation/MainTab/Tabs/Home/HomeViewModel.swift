//
//  HomeViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    
    @Published var bestPopups: [Popup] = []
    @Published var comingPopups: [Popup] = []
    @Published var gridPopups: [Popup] = []
    
    // 내가 좋아요한 팝업 id 모음
    @Published var likePostIds: Set<UUID> = []
    
    init() {
        Task {
            do {
                // 백그라운드 스레드에서 비동기 처리
                let popups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.bestPopups = popups
                }
                
                let comingPopups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.comingPopups = comingPopups
                }
                
                let gridPopups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.gridPopups = gridPopups
                }
                
            } catch {
                print("❌ getPopupList Error: \(error)")
            }
        }
    }
    
    
    /// 좋아요 상태 바꿔주는 함수
    func toggleLike(popup: Popup) {
        if likePostIds.contains(popup.id) {
            likePostIds.remove(popup.id)
        } else {
            likePostIds.insert(popup.id)
        }
    }
    
    /// 팝업이 좋아요 눌린 상태인지 체크
    func isLiked(popup: Popup) -> Bool {
        likePostIds.contains(popup.id)
    }
}
