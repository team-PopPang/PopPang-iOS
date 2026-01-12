//
//  TrendingCategory.swift
//  PopPang
//
//  Created by 김동현 on 1/12/26.
//

import Foundation

enum TrendingCategory: CaseIterable, Identifiable {
    var id: Self { self }
    // case all
    case dubaiStickyCookie
    
    var title: String {
        switch self {
        // case .all: return "전체"
        case .dubaiStickyCookie: return "🍪 두바이쫀득쿠키"
        }
    }
}
