//
//  CalendarViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/12/25.
//

import Foundation

final class CalendarViewModel: ObservableObject {
    let userUuid: String
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    
    @Published var calendarPopups: [Popup] = []
    
    init(userUuid: String) {
        self.userUuid = "test"
        
        
        Task {
            do {
                let popups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.calendarPopups = popups
                }
            } catch {
                print("❌ getPopupList Error: \(error)")
            }
        }
    }
}
