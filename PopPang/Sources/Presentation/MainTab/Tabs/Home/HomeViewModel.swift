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
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await withThrowingTaskGroup(of: (Int, [Popup]).self) {  group in
                    // 0, 1, 2로 구분해서 요청
                    group.addTask { (0, try await self.popupUsecase.getPopupList()) }
                    group.addTask { (1, try await self.popupUsecase.getPopupList()) }
                    group.addTask { (2, try await self.popupUsecase.getPopupList()) }

                    // 완료된 순서대로 결과 받기
                    for try await (index, popups) in group {
                        await MainActor.run {
                            switch index {
                            case 0:
                                self.bestPopups = popups
                            case 1:
                                self.comingPopups = popups
                            case 2:
                                self.gridPopups = popups
                            default:
                                break
                            }
                        }
                    }
                }
            } catch {
                print("❌ 네트워크 오류:", error)
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
