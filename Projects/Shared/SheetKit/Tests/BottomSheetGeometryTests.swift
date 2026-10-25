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

    @Test("소수점 끝자리만 다른 높이는 같은 높이로 보고, 0.5pt보다 크게 바뀌면 다르다고 본다")
    func tinyChangesAreIgnored() {
        // 지도 화면이 멈췄을 때 디버거로 찍은 값이다. 끝자리 하나만 다르다.
        let before = BottomSheetGeometry(height: 681.22222222222217, maxHeight: 732.77777777777771)
        let jittered = BottomSheetGeometry(height: 681.22222222222229, maxHeight: 732.77777777777783)
        let moved = BottomSheetGeometry(height: 682, maxHeight: 732.77777777777771)

        #expect(!jittered.isMeaningfullyDifferent(from: before))
        #expect(moved.isMeaningfullyDifferent(from: before))
        #expect(before.isMeaningfullyDifferent(from: nil))
        #expect(!BottomSheetMetrics.isMeaningfulChange(from: 869.77777777777783, to: 869.77777777777771))
        #expect(BottomSheetMetrics.isMeaningfulChange(from: 869.5, to: 870.1))
    }
}
