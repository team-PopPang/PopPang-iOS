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
}
