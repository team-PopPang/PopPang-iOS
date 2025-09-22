//
//  MainTabType.swift
//  PopPang
//
//  Created by 김동현 on 9/22/25.
//

import Foundation

enum MainTabType: String, CaseIterable {
    case home
    case calendar
    case map
    case bookmark
    case profile
    
    var title: String {
        switch self {
        case .home: return "홈"
        case .calendar: return "캘린더"
        case .map: return "팝팡지도"
        case .bookmark: return "팝팡"
        case .profile: return "마이"
        }
    }
    
    func tabImage(selected: Bool) -> String {
        return selected ? "\(rawValue)_fill" : rawValue
    }
}

