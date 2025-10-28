//
//  RegionListDTO.swift
//  PopPang
//
//  Created by 김동현 on 10/28/25.
//

import Foundation

// MARK: - DTO
struct RegionListDTO: Decodable, Hashable {
    let region: String
    let districts: [String]
    
    func toEntity() -> RegionList{
        return RegionList(region: region, districts: districts)
    }
}
