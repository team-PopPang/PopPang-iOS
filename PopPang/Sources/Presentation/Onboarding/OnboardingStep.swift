//
//  OnboardingStep.swift
//  DevNote
//
//  Created by 김동현 on 9/6/25.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case keyword = 0
    case map
    case favorite
    
    var logo: String {
        switch self {
        case .keyword: "Logo1"
        case .map: "Logo2"
        case .favorite: "Logo3"
        }
    }
    
    var title: String {
        switch self {
        case .keyword:
            NSLocalizedString("onboarding.keyword.title", comment: "Onboarding title for keyword notifications")
        case .map:
            NSLocalizedString("onboarding.map.title", comment: "Onboarding title for map-based service")
        case .favorite:
            NSLocalizedString("onboarding.favorite.title", comment: "Onboarding title for favorites calendar")
        }
    }
    
    var content: String {
        switch self {
        case .keyword:
            NSLocalizedString("onboarding.keyword.content", comment: "Onboarding body for keyword notifications")
        case .map:
            NSLocalizedString("onboarding.map.content", comment: "Onboarding body for nearby popup map")
        case .favorite:
            NSLocalizedString("onboarding.favorite.content", comment: "Onboarding body for favorites calendar")
        }
    }
    
//    var content: String {
//        switch self {
//        case .keyword:
//            """
//            키워드를 등록하여
//            관련 팝업스토어를 알림 받아보세요.
//            """
//        case .map:
//            """
//            주변에서 열리는 팝업을
//            지도에서 바로 확인할 수 있어요.
//            """
//        case .favorite:
//            """
//            찜한 팝업만 캘린더로 모아
//            한눈에 일정으로 확인할 수 있어요.
//            """
//        }
//    }
    
    var image: String {
        switch self {
        case .keyword: "Onboarding1"
        case .map: "Onboarding2"
        case .favorite: "Onboarding3"
        }
    }
}
