//
//  PopupRepositoryProtocol.swift
//  PopPang
//
//  Created by 김동현 on 10/8/25.
//

import Foundation

protocol PopupRepositoryProtocol {
    
    /// 팝업리스트를 가져옵니다
    /// - Returns: [PopupDTO]
    func getPopupList() async throws -> [PopupDTO]
}
