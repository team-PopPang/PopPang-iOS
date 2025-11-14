//
//  OnboardingStep.swift
//  DevNote
//
//  Created by 김동현 on 9/6/25.
//

import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case keyword
    case map
    case favorite
    
    var title: String {
        switch self {
        case .welcome:
            "팝팡에 오신 걸 환영해요"
        case .keyword:
            "키워드 알림"
        case .map:
            "지도"
        case .favorite:
            "찜등록"
        }
    }
    
    var content: String {
        switch self {
        case .welcome:
            """
            팝업 찾느라 힘들었죠?
            이제 팝팡이 알아서 찾아줄게요.
            """
        case .keyword:
            """
            키워드를 등록하여
            관련 팝업스토어를 알림 받아보세요.
            """
        case .map:
            """
            주변에서 열리는 팝업을
            지도에서 바로 확인할 수 있어요.
            """
        case .favorite:
            """
            찜한 팝업만 캘린더로 모아
            한눈에 일정으로 확인할 수 있어요.
            """
        }
    }
    
    var image: String {
        switch self {
        case .welcome: "Onboarding0"
        case .keyword: "Onboarding1"
        case .map: "Onboarding2"
        case .favorite: "Onboarding3"
        }
    }
}
