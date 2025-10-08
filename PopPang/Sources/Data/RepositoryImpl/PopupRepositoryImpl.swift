//
//  PopupRepositoryImpl.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

final class PopupRepositoryImpl: PopupRepositoryProtocol {
    func getPopupList() async throws -> [PopupDTO] {
        do {
            let response = try await NetworkProvider.shared.popupProvidder.asyncRequest(.getPopupList, decodeTo: [PopupDTO].self)
            return response
        } catch {
            throw error
        }
    }
}
