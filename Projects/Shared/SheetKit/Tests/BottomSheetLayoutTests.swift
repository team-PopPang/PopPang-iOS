import CoreGraphics
@testable import SheetKit
import Testing

struct BottomSheetLayoutTests {
    /// 높이 800인 뷰에 위쪽 여백 100을 둔다. 올릴 수 있는 끝은 700이다.
    private let layout = BottomSheetLayout(containerHeight: 800, topInset: 100)

    @Test("비율 단계는 시트를 붙인 뷰 높이를 기준으로 계산한다")
    func fractionUsesContainerHeight() {
        #expect(layout.height(for: .medium) == 400)
        #expect(layout.height(for: .fraction(0.25)) == 200)
    }

    @Test(".large는 위쪽 여백을 뺀 높이다")
    func largeExcludesTopInset() {
        #expect(layout.height(for: .large) == 700)
    }

    @Test("높이는 0보다 작거나 올릴 수 있는 끝보다 클 수 없다")
    func heightIsClamped() {
        #expect(layout.height(for: .height(900)) == 700)
        #expect(layout.height(for: .fraction(0.95)) == 700)
        #expect(layout.height(for: .height(-10)) == 0)
    }

    @Test("위쪽 여백이 뷰보다 크면 모든 높이가 0이다")
    func topInsetLargerThanContainer() {
        let layout = BottomSheetLayout(containerHeight: 300, topInset: 400)

        #expect(layout.maxHeight == 0)
        #expect(layout.height(for: .medium) == 0)
    }

    @Test("단계는 높이가 낮은 순서로 정렬하고, 비어 있으면 .large만 쓴다")
    func sortedDetents() {
        #expect(layout.sortedDetents([.large, .fraction(0.25), .medium]) == [.fraction(0.25), .medium, .large])
        #expect(layout.sortedDetents([]) == [.large])
    }

    @Test("멈춘 채로 손을 떼면 그 높이에서 가장 가까운 단계에 멈춘다")
    func targetIsNearestDetent() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 520, velocity: 0, in: detents, canHide: true) == .medium)
        #expect(layout.targetDetent(releasedHeight: 580, velocity: 0, in: detents, canHide: true) == .large)
    }

    @Test("손을 뗀 속도는 초속 1,000pt마다 약 99pt만 더 가게 반영한다")
    func projectedDistanceIsShort() {
        #expect(abs(BottomSheetLayout.projectedDistance(for: 1_000) - 99) < 0.001)
        #expect(abs(BottomSheetLayout.projectedDistance(for: -2_000) + 198) < 0.001)
    }

    @Test("튕기면 속도만큼 더 간 높이에서 가장 가까운 단계에 멈춘다")
    func flickMovesTowardVelocity() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 450, velocity: -2_000, in: detents, canHide: true) == .large)
        #expect(layout.targetDetent(releasedHeight: 650, velocity: 2_000, in: detents, canHide: true) == .medium)
    }

    @Test("끝까지 올린 시트를 살짝 튕겨 내리면 숨지 않고 가운데 단계에 멈춘다")
    func shortFlickFromTopStopsAtMedium() {
        let detents = layout.sortedDetents([.medium, .large])

        // 700에서 60pt 내리고 초속 2,500pt로 놓은 경우. 예상 높이는 약 392.5다.
        #expect(layout.targetDetent(releasedHeight: 640, velocity: 2_500, in: detents, canHide: true) == .medium)
    }

    @Test("가장 낮은 단계에서 세게 튕겨 내리면 숨긴다")
    func strongFlickFromLowestDetentHides() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 400, velocity: 3_000, in: detents, canHide: true) == nil)
    }

    @Test("숨길 수 있으면 가장 낮은 단계의 절반보다 아래에서 숨긴다")
    func hidesBelowHalfOfLowestDetent() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 199, velocity: 0, in: detents, canHide: true) == nil)
        #expect(layout.targetDetent(releasedHeight: 201, velocity: 0, in: detents, canHide: true) == .medium)
    }

    @Test("숨길 수 없으면 아무리 내려도 가장 낮은 단계에 멈춘다")
    func staysAtLowestDetentWhenCannotHide() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 0, velocity: 3_000, in: detents, canHide: false) == .medium)
    }

    @Test("목록에 없는 높이에서 놓아도 가까운 단계에 멈춘다")
    func unknownHeightSnapsToNearestDetent() {
        let detents = layout.sortedDetents([.medium, .large])
        let releasedHeight = layout.height(for: .height(450))

        #expect(layout.targetDetent(releasedHeight: releasedHeight, velocity: 0, in: detents, canHide: true) == .medium)
    }

    @Test("액세서리는 가장 높은 단계 바로 아래 단계까지 보이고, 가장 높은 단계로 갈수록 흐려져 숨는다")
    func accessoryFadesOutTowardHighestDetent() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.accessoryOpacity(sheetHeight: 300, in: detents) == 1)
        #expect(layout.accessoryOpacity(sheetHeight: 400, in: detents) == 1)
        #expect(layout.accessoryOpacity(sheetHeight: 550, in: detents) == 0.5)
        #expect(layout.accessoryOpacity(sheetHeight: 700, in: detents) == 0)
    }

    @Test("단계가 하나뿐이면 액세서리는 높이 0부터 그 단계까지 흐려진다")
    func accessoryFadesFromZeroWithSingleDetent() {
        let detents = layout.sortedDetents([.large])

        #expect(layout.accessoryOpacity(sheetHeight: 0, in: detents) == 1)
        #expect(layout.accessoryOpacity(sheetHeight: 350, in: detents) == 0.5)
        #expect(layout.accessoryOpacity(sheetHeight: 700, in: detents) == 0)
    }

    @Test("손잡이를 누르면 위로 한 단계, 맨 위에서는 아래로 한 단계 간다")
    func tapMovesOneStep() {
        let detents = layout.sortedDetents([.fraction(0.25), .medium, .large])

        #expect(layout.detentAfterTap(from: .fraction(0.25), in: detents) == .medium)
        #expect(layout.detentAfterTap(from: .medium, in: detents) == .large)
        #expect(layout.detentAfterTap(from: .large, in: detents) == .medium)
    }

    @Test("VoiceOver로 높이를 올리고 내리면 한 단계씩 움직이고, 숨길 수 있을 때만 숨긴다")
    func adjustableActions() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.detentAfterIncrement(from: .medium, in: detents) == .large)
        #expect(layout.detentAfterIncrement(from: .large, in: detents) == .large)
        #expect(layout.detentAfterDecrement(from: .large, in: detents, canHide: true) == .medium)
        #expect(layout.detentAfterDecrement(from: .medium, in: detents, canHide: true) == nil)
        #expect(layout.detentAfterDecrement(from: .medium, in: detents, canHide: false) == .medium)
    }
}
