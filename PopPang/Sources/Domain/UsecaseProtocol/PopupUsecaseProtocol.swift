//
//  PopupUsecaseProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

protocol PopupUsecaseProtocol {
    func getPopupList() async throws -> [Popup]
}
