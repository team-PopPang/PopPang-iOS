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
}
