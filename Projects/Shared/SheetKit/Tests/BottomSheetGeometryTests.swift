import CoreGraphics
@testable import SheetKit
import Testing

struct BottomSheetGeometryTests {
    @Test("겹친 시트 가운데 더 높이 올라온 시트의 높이를 넘긴다")
    func higherSheetWins() {
        let list = BottomSheetGeometry(height: 300, maxHeight: 700)
        let option = BottomSheetGeometry(height: 450, maxHeight: 700)

        #expect(BottomSheetGeometry.higher(list, option) == option)
        #expect(BottomSheetGeometry.higher(option, list) == option)
    }

    @Test("한쪽 시트만 알리면 그 시트를 넘기고, 아무도 알리지 않으면 없다")
    func missingSheetIsIgnored() {
        let list = BottomSheetGeometry(height: 0, maxHeight: 700)

        #expect(BottomSheetGeometry.higher(nil, list) == list)
        #expect(BottomSheetGeometry.higher(list, nil) == list)
        #expect(BottomSheetGeometry.higher(nil, nil) == nil)
    }
}
