import Foundation
import Testing
@testable import Core

struct FoundationExtensionsTests {
    @Test("Core 날짜 포매터가 팝업과 서버 시간 형식을 제공한다")
    func providesCoreDateFormatters() {
        #expect(DateFormatter.popupDateFormat.dateFormat == "yy.MM.dd")
        #expect(DateFormatter.popupTimeFormat.dateFormat == "HH:mm")
        #expect(DateFormatter.serverTimeFormat.dateFormat == "HH:mm:ss")
    }

    @Test("주소 문자열에서 앞 두 구성요소만 짧은 주소로 반환한다")
    func shortAddressReturnsOnlyFirstTwoComponents() {
        #expect("서울 성동구 성수동".shortAddress == "서울 성동구")
        #expect("서울".shortAddress == "서울")
    }
}
