//
//  Constants.swift
//  PopPang
//
//  Created by 김동현 on 9/24/25.
//

import Foundation

enum Constants {
    enum PopPangAPI {
        static let url = "https://index.zapto.org/api/oauth2/appleLogin"
    }
    
    enum KakaoAPI {
        // static let key = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String ?? ""
        static let key = {
            if let key = Bundle.main.infoDictionary?["KAKAO_NATIVE_APP_KEY"] as? String {
                return key
            } else {
                fatalError("❌ KAKAO_NATIVE_APP_KEY가 Info.plist에 등록되지 않았습니다.")
            }
        }()
    }
    
    enum BetaNotice {
        static let beta_0930 = """
        홈화면 
        • 좌측 드롭다운버튼 글자 17(bold)
        • 우측 드롭다운버튼 글자 12(regular)
        • 스크롤뷰 제일 하단 여백 추가
        
        팝업 상세화면
        • 글자 24(bold), 15(regular), 12(regular)
        • 좋아요 제거
        • 알림 받기 => 찜하기 변경
        """
    }
}


