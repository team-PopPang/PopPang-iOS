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
    let districtList: [String]
    
    func toEntity() -> RegionList{
        return RegionList(region: region, districtList: districtList)
    }
}
