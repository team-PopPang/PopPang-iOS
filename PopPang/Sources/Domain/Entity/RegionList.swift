//
//  RegionList.swift
//  PopPang
//
//  Created by 김동현 on 10/28/25.
//

import Foundation

// MARK: - Entity
struct RegionList: Identifiable, Hashable {
    var id: String { region }
    let region: String
    let districts: [String]
}
