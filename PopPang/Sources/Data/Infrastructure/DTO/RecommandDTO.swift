//
//  RecommandDTO.swift
//  PopPang
//
//  Created by 김동현 on 10/9/25.
//

import Foundation

struct RecommendListDTO: Decodable, Identifiable {
    let id: Int
    let recommendName: String
}

extension RecommendListDTO {
    func toModel() -> RecommendList {
        RecommendList(id: id,
                  recommendName: recommendName)
    }
}
