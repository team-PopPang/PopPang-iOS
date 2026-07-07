//
//  Keyword.swift
//  PopPang
//
//  Created by 김동현 on 10/13/25.
//

import Foundation

struct Keyword: Encodable, Equatable {
    let id: String
    let keyword: String
    
    init(keyword: String) {
        self.id = keyword // 키워드 자체를 고유ID로 사용
        self.keyword = keyword
    }
}
