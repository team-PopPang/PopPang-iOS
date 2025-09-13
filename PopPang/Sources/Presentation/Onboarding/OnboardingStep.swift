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
    case alert
    case favorite
    
    var title: String {
        switch self {
        case .welcome:
            "PopPang에 오신 걸 환영해요"
        case .keyword:
            "키워드 설정"
        case .alert:
            "실시간 알림"
        case .favorite:
            "즐겨찾기 관리"
        }
    }
    
    var content: String {
        switch self {
        case .welcome:
            """
            팝업스토어 소식, 일일이 찾느라 힘드셨죠?
            이제 PopPang 하나면 충분해요.
            원하는 팝업 정보를 모아
            빠르고 편리하게 확인하세요.
            """
        case .keyword:
            """
            관심 있는 아티스트, 브랜드,
            키워드를 등록해보세요.
            딱 맞는 팝업 정보만
            골라서 알려드립니다.
            """
        case .alert:
            """
            새로운 팝업스토어가 열리면
            실시간으로 알림을 받아보세요.
            놓치고 싶지 않은 이벤트를
            제때 확인할 수 있습니다.
            """
        case .favorite:
            """
            관심 있는 팝업은 즐겨찾기에 저장!
            오픈 임박 알림도 받고,
            나만의 팝업 캘린더로 관리하세요.
            """
        }
    }
    
    var image: Image {
        switch self {
        default:
            Image(systemName: "person")
        }
    }
}
