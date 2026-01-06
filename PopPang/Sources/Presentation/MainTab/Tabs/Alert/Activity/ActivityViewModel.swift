//
//  ActivityViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/30/25.
//

import Foundation

final class ActivityViewModel: ObservableObject {
    let userUuid: String
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var alertPopupList: [Popup] = []
    
    // 삭제 로직
    @Published var isEditing: Bool = false
    // @Published var showDeleteAlert: Bool = false
    
    
    init(userUuid: String) {
        self.userUuid = userUuid
    }
    
    private func getAlertPopupList() async -> [Popup] {
        do {
            let getActivityPopupList = try await popupUsecase.getAlertPopupList(userUuid: userUuid)
            return getActivityPopupList
        } catch {
            Logger.e("알림 리스트 가져오기 실패: \(error)")
            return []
        }
    }
}

// MARK: - 비동기 불러오기(View)
extension ActivityViewModel {
    // view 호출 전용
    func getAlertPopupListForView() async {
        do {
            let getActivityPopupList = try await popupUsecase.getAlertPopupList(userUuid: userUuid)
            await MainActor.run {
                self.alertPopupList = getActivityPopupList
            }
        } catch {
            Logger.e("알림 리스트 가져오기 실패: \(error)")
        }
    }
}

// MARK: - 삭제 로직
extension ActivityViewModel {
    
    // 단건 삭제
    func deleteSelectedPopups(popupUuid: String) {
        Task {
            do {
                // MARK: - 비동기 함수
                try await popupUsecase.removeAlertPopup(userUuid: userUuid,
                                                        popupUuid: popupUuid)
                
                // MARK: - UI삭제
                await MainActor.run {
                    alertPopupList.removeAll { $0.popupUuid == popupUuid }
                }
            } catch {
                Logger.e("\(error)")
            }
        }
    }
    
    // 전체 삭제
    func deleteAllSelectedPopups() {
        Task {
            
            // MARK: - 비동기 함수
            do {
                for popup in alertPopupList {
                    try await popupUsecase.removeAlertPopup(userUuid: userUuid, popupUuid: popup.popupUuid)
                }
                
                // MARK: - UI 삭제
                await MainActor.run {
                    alertPopupList.removeAll()
                }
            } catch {
                Logger.e("\(error)")
            }
        }
    }
}


// MARK: - 찜 관련
extension ActivityViewModel {
    /// 팝업이 좋아요 눌린 상태인지 체크
    func isLiked(popup: Popup) -> Bool {
        return popup.isFavorited
    }
    
    /*
    /// 좋아요 상태 바꿔주는 함수
    func toggleLike(popup: Popup) async {
        do {
            let popupUuid = popup.popupUuid
            
            // 좋아요 취소
            if popup.isFavorited {
                try await popupUsecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
                
                await MainActor.run {
                    // 목록 갱신
                    if let index = self.alertPopupList.firstIndex(where: { $0.popupUuid == popupUuid }) {
                        // 좋아요 취소
                        self.alertPopupList[index].isFavorited = false
                        
                        // 좋아요 -1
                        let count = self.alertPopupList[index].favoriteCount
                        self.alertPopupList[index].favoriteCount = max(0, count - 1)
                    }
                }
            } else {
                try await popupUsecase.addFavorite(userUuid: userUuid, popupUuid: popup.popupUuid)
                await MainActor.run {
                    // 목록 갱신
                    if let index = self.alertPopupList.firstIndex(where: { $0.popupUuid == popupUuid }) {
                        // 좋아요 추가
                        self.alertPopupList[index].isFavorited = true
                        
                        // 좋아요 +1
                        self.alertPopupList[index].favoriteCount += 1
                    }
                }
            }
        } catch {
            Logger.e("\(error)")
        }
    }
     */
    
    @MainActor
    func toggleLike(popupUuid: String) async {
        
        guard let index = alertPopupList.firstIndex(where: { $0.popupUuid == popupUuid }) else { return }
        
        // 최신 상태
        let isLiked = alertPopupList[index].isFavorited
        
        // 좋아요 취소
        if isLiked {
            
            // 취소 로직
            do {
                // Optimistic Update(UI 먼저 반영)
                alertPopupList[index].isFavorited = false
                alertPopupList[index].favoriteCount = max(0, alertPopupList[index].favoriteCount - 1)
                
                try await popupUsecase.removeFavorite(userUuid: userUuid, popupUuid: popupUuid)
                Logger.d("취소 성공")
            } catch {
                // 실패 시 롤백
                alertPopupList[index].isFavorited = true
                alertPopupList[index].favoriteCount += 1
                Logger.e("\(error)")
            }
        } else {
            // 추가 로직
            do {
                // Optimistic Update(UI 먼저 반영)
                alertPopupList[index].isFavorited = true
                alertPopupList[index].favoriteCount += 1
                
                try await popupUsecase.addFavorite(userUuid: userUuid, popupUuid: popupUuid)
                Logger.d("추가 성공")
            } catch {
                // ❗ 실패 시 롤백
                alertPopupList[index].isFavorited = false
                alertPopupList[index].favoriteCount =
                max(0, alertPopupList[index].favoriteCount - 1)
                Logger.e("\(error)")
            }
        }
    }
}
