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
    @Published var selectedPopupIds: Set<String> = []
    @Published var showDeleteAlert: Bool = false
    
    
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
    func checkBoxTapped(popup: Popup) {
        if selectedPopupIds.contains(popup.popupUuid) {
            selectedPopupIds.remove(popup.popupUuid)
        } else {
            selectedPopupIds.insert(popup.popupUuid)
        }
    }
    
    // 선택된 팝업들만 activity 목록에서 삭제
    func deleteSelectedPopups() {
        Task {
            do {
                // MARK: - 비동기 함수
                for id in selectedPopupIds {
                    try await popupUsecase.removeAlertPopup(userUuid: userUuid,
                                                            popupUuid: id)
                }
                 
                try await Task.sleep(nanoseconds: 1_000_000_000) 
                
                // MARK: - UI 삭제
                await MainActor.run {
                    alertPopupList.removeAll { popup in         // 전체 팝업 목록
                        selectedPopupIds.contains(popup.popupUuid) // 체크된 팝업 목록
                    }
                    selectedPopupIds.removeAll()
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
}
