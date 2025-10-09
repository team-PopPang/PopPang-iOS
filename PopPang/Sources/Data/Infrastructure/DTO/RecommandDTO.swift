//
//  RecommandDTO.swift
//  PopPang
//
//  Created by 김동현 on 10/9/25.
//

import Foundation

struct RecommandDTO: Decodable, Identifiable {
    let id: Int
    let recommendName: String
}

extension RecommandDTO {
    func toEntity() -> Recommand {
        Recommand(id: id,
                  recommendName: recommendName)
    }
}
