//
//  HomeViewModel.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import Foundation

final class HomeViewModel: ObservableObject {
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    let userUuid: String
    
    @Published var bestPopups: [Popup] = []
    @Published var comingPopups: [Popup] = []
    @Published var gridPopups: [Popup] = []
    
    // 내가 좋아요한 팝업 uuid 모음
    @Published var likePostIds: Set<String> = []
    
    
    
    init(userUuid: String) {
        self.userUuid = userUuid
        
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
    
    /// 팝업이 좋아요 눌린 상태인지 체크
    func isLiked(popup: Popup) -> Bool {
        likePostIds.contains(popup.popupUuid)
    }
    
    /// 좋아요 상태 바꿔주는 함수
    func toggleLike(popup: Popup) {
        if likePostIds.contains(popup.popupUuid) {
            likePostIds.remove(popup.popupUuid)
        } else {
            likePostIds.insert(popup.popupUuid)
        }
    }
}
