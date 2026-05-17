import Foundation
import Testing
@testable import Core

struct FoundationExtensionsTests {
    @Test
    func providesCoreDateFormatters() {
        #expect(DateFormatter.popupDateFormat.dateFormat == "yy.MM.dd")
        #expect(DateFormatter.popupTimeFormat.dateFormat == "HH:mm")
        #expect(DateFormatter.serverTimeFormat.dateFormat == "HH:mm:ss")
    }

    @Test
    func shortAddressReturnsOnlyFirstTwoComponents() {
        #expect("서울 성동구 성수동".shortAddress == "서울 성동구")
        #expect("서울".shortAddress == "서울")
    }
}
