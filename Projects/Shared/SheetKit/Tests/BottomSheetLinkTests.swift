import CoreGraphics
@testable import SheetKit
import Testing

struct BottomSheetLinkTests {
    @Test("위에 겹친 시트가 없으면 같이 움직일 거리가 없다")
    func totalTranslationWithoutLinks() {
        let links: [BottomSheetLink] = []

        #expect(links.totalTranslation == 0)
    }

    @Test("위에 겹친 시트들을 끄는 거리를 모두 더한다")
    func totalTranslationAddsAllLinks() {
        let top = BottomSheetLink()
        let middle = BottomSheetLink()
        let links = [top, middle]

        top.translation = 30
        #expect(links.totalTranslation == 30)

        middle.translation = 10
        #expect(links.totalTranslation == 40)
    }
}
