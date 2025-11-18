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
            "팝업스토어 알림"
        case .map:
            "위치 기반 서비스"
        case .favorite:
            "캘린더형 찜 리스트"
        }
    }
    
    var content: String {
        switch self {
        case .keyword:
            """
            언제 어디서 확인 가능하고
            """
        case .map:
            """
            언제 어디서 확인 가능하고
            """
        case .favorite:
            """
            언제 어디서 확인 가능하고
            """
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
