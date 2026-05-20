import SwiftUI
import Testing
@testable import DSKit

struct DesignTokenTests {
    @Test
    func providesExpectedSpacingAndFontTokens() {
        #expect(CGFloat.contentPadding == 15)
        #expect(CGFloat.cornerRadius == 5)
        #expect(Font.title1 == Font.scdream(.medium, size: 12))
    }

    @Test
    func createsColorFromHex() {
        let color = Color(hex: "#FF7A00")
        let uiColor = color.uiColor

        #expect(uiColor.cgColor.alpha == 1.0)
    }
}
