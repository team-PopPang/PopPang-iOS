import CoreGraphics
import Foundation
@testable import SheetKit
import Testing

struct BottomSheetDragTests {
    @Test("진행 중인 끌기가 없으면 어느 곳에서든 새로 시작한다")
    func beginsWithoutCurrentDrag() {
        #expect(BottomSheetDrag.decision(for: .grabber, current: nil) == .begin)
        #expect(BottomSheetDrag.decision(for: .background, current: nil) == .begin)
        #expect(BottomSheetDrag.decision(for: .handle(UUID()), current: nil) == .begin)
    }

    @Test("시트를 움직이는 끌기와 같은 곳에서 온 알림은 이어 간다")
    func followsSameSource() {
        let handle = UUID()

        #expect(
            BottomSheetDrag.decision(
                for: .handle(handle),
                current: BottomSheetDrag(source: .handle(handle), isHorizontal: false)
            ) == .follow
        )
        #expect(
            BottomSheetDrag.decision(
                for: .background,
                current: BottomSheetDrag(source: .background, isHorizontal: true)
            ) == .follow
        )
    }

    @Test("다른 곳에서 시작한 끌기가 시트를 움직이는 동안 온 알림은 무시한다")
    func ignoresOtherSources() {
        let current = BottomSheetDrag(source: .grabber, isHorizontal: false)

        #expect(BottomSheetDrag.decision(for: .background, current: current) == .ignore)
        #expect(BottomSheetDrag.decision(for: .handle(UUID()), current: current) == .ignore)
    }

    @Test("서로 다른 손잡이 뷰는 다른 곳으로 본다")
    func distinguishesHandles() {
        let current = BottomSheetDrag(source: .handle(UUID()), isHorizontal: false)

        #expect(BottomSheetDrag.decision(for: .handle(UUID()), current: current) == .ignore)
    }

    @Test("가로로 더 많이 움직이며 시작한 끌기만 가로 끌기로 본다")
    func detectsHorizontalDrag() {
        #expect(BottomSheetDrag.isHorizontal(CGSize(width: 12, height: 3)))
        #expect(BottomSheetDrag.isHorizontal(CGSize(width: -12, height: 3)))
        #expect(!BottomSheetDrag.isHorizontal(CGSize(width: 3, height: -12)))
        #expect(!BottomSheetDrag.isHorizontal(CGSize(width: 10, height: 10)))
    }
}
