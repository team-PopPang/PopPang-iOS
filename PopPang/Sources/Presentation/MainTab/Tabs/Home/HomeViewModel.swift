//
//  HomeViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    @Published var bestPopups: [Popup] = Popup.popupMocks
    @Published var comingPopups: [Popup] = Array(Popup.popupMocks[4...])
    @Published var gridPopups: [Popup] = Array(Popup.popupMocks[7...])
    
    // 내가 좋아요한 팝업 id 모음
    @Published var likePostIds: Set<UUID> = []
    
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
