//
//  CheckNicknameDTO.swift
//  PopPang
//
//  Created by 김동현 on 10/3/25.
//

import Foundation

// MARK: - 닉네임 파서
struct CheckNicknameDTO: Decodable {
    let isDuplicated: Bool
}
