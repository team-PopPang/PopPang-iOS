//
//  CalendarViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/12/25.
//

import Foundation

final class CalendarViewModel: ObservableObject {
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    
    @Published var calendarPopups: [Popup] = []
    
    init() {
        print("❌❌❌❌❌❌❌❌❌❌❌")
        Task {
            do {
                let popups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.calendarPopups = popups
                    print(popups)
                }
            } catch {
                print("❌ getPopupList Error: \(error)")
            }
        }
    }
}
