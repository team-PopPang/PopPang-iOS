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
        
        Task {
            let getAlertPopupList =  await getAlertPopupList()
            await MainActor.run {
                self.alertPopupList = getAlertPopupList
            }
        }
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

// MARK: - 
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
