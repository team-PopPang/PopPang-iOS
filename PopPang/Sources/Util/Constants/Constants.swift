//
//  Constants.swift
//  PopPang
//
//  Created by 김동현 on 9/24/25.
//

import Foundation

enum Constants {
    enum PopPangAPI {
        static let apiURL = "https://poppang.co.kr/api/v1"
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
        
        static let beta_0931 = """
        홈화면 
        • 찜버튼 생성
        • 곧생기는 팝업 UI 수정
        • 검색 터치시 키보드 자동 올라오기 반영
        • (검색창 최근 본 검색어 UI 수정예정)
        
        팝업 상세화면
        • 자간(102%), 행간(140%) 반영
        • 공유하기 버튼 수정
        """
        
        static let beta_1002 = """
        홈화면 
        • 검색창, 곧 생기는 팝업 디자인 변경
        • 검색창 최근 검색어 기능 추가(목업 데이터)
        """
    }
}
