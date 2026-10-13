import CoreGraphics
@testable import SheetKit
import Testing

struct BottomSheetLinkTests {
    @Test("위에 겹친 시트가 없으면 이 시트를 끄는 거리만 아래 시트로 넘긴다")
    func translationWithoutLinkAbove() {
        let link = BottomSheetLink()
        link.ownTranslation = 30

        #expect(link.translation == 30)
    }

    @Test("위에 겹친 시트를 끄는 거리는 그 아래 시트들까지 이어진다")
    func translationAddsLinkAbove() {
        let top = BottomSheetLink()
        let middle = BottomSheetLink()
        middle.linkAbove = top

        top.ownTranslation = 30
        #expect(middle.translation == 30)

        middle.ownTranslation = 10
        #expect(middle.translation == 40)
    }
}
