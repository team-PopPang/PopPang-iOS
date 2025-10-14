//
//  KeywordDTO.swift
//  PopPang
//
//  Created by 김동현 on 10/13/25.
//

import Foundation

struct KeywordDTO: Decodable, Identifiable {
    var id: String { keyword }
    let keyword: String
    
    enum CodingKeys: String, CodingKey {
        case keyword = "alertKeyword"
    }
}

extension KeywordDTO {
    func toModel() -> Keyword {
        Keyword(keyword: keyword)
    }
}


