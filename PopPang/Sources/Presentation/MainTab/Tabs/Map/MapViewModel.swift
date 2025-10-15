//
//  MapViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/15/25.
//

import Foundation

final class MapViewModel: ObservableObject {
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var mapPopups: [Popup] = []
    
    init() {
        Task {
            do {
                let popups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.mapPopups = popups
                }
            } catch {
                print("❌ MapViewModel getPopupList Error: \(error)")
            }
        }
    }
}
