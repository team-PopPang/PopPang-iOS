import Foundation

public enum Constants {
    public enum URL {
        public static let notification = ExternalLinkConfig.notificationURLString
        public static let serviceTerms = ExternalLinkConfig.serviceTermsURLString
    }

    public enum PopPangAPI {
        public static let apiURL = NetworkConfig.apiURLString
        public static let imageURL = NetworkConfig.imageURLString
    }

    public enum KakaoAPI {
        public static let key = AppConfig.string(forKey: "KAKAO_NATIVE_APP_KEY")
    }

    public enum NaverAPI {
        public static let key = AppConfig.string(forKey: "NMFClientID")
    }

    public enum AdMob {
        public static let nativeAdUnitId = AppConfig.string(forKey: "ADMOB_NATIVE_AD_UNIT_ID")
        // Google Mobile Ads 공식 iOS Native 테스트 광고 단위 ID
        public static let testNativeAdUnitId = "ca-app-pub-3940256099942544/3986624511"

        public static var currentNativeAdUnitId: String {
            #if DEBUG
                testNativeAdUnitId
            #else
                nativeAdUnitId
            #endif
        }
    }

    public enum BetaNotice {
        public static let beta_0930 = """
        홈화면
        • 좌측 드롭다운버튼 글자 17(bold)
        • 우측 드롭다운버튼 글자 12(regular)
        • 스크롤뷰 제일 하단 여백 추가

        팝업 상세화면
        • 글자 24(bold), 15(regular), 12(regular)
        • 좋아요 제거
        • 알림 받기 => 찜하기 변경
        """

        public static let beta_0931 = """
        홈화면
        • 찜버튼 생성
        • 곧생기는 팝업 UI 수정
        • 검색 터치시 키보드 자동 올라오기 반영
        • (검색창 최근 본 검색어 UI 수정예정)

        팝업 상세화면
        • 자간(102%), 행간(140%) 반영
        • 공유하기 버튼 수정
        """

        public static let beta_1002 = """
        홈화면
        • 검색창, 곧 생기는 팝업 디자인 변경
        • 검색창 최근 검색어 기능 추가(목업 데이터)
        """

        public static let beta_1004 = """
        로그인
        • 로그인 기능 성공!!
        """

        public static let beta_1005 = """
        홈화면
        • 드롭다운 버튼을 제외한 나머지 피드백 반영
        • 콘텐츠 사이 50패딩 설정했는데 패딩이 큰 느낌

        알림화면
        • 활동 화면 90% 완성
        • 키워드 설정 진행중
        """

        public static let beta_1008 = """
        홈화면
        • 실제 팝업 데이터 보이도록 수정

        팝업 상세화면
        • 날짜 오류 수정

        알림화면
        • 알림화면 UI 구현 완료
        • 키워드 설정 입력창 UI 디자인을 추후 변경 예정(참고)
        """

        public static let beta_1012 = """
        홈화면
        • 피그마 피드백 아직 미반영
          (월요일에 반영 예정)

        캘린더화면
        • 월간 부분 90% 완성
        """
    }
}
