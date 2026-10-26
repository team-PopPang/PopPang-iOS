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

    @Test("최대 높이로 그린 시트는 보일 높이만큼만 올라오도록 나머지를 아래로 내린다")
    func offsetLeavesVisibleHeight() {
        #expect(layout.offset(forVisibleHeight: 700) == 0)
        #expect(layout.offset(forVisibleHeight: 400) == 300)
        #expect(layout.offset(forVisibleHeight: 20) == 680)
        // 끝까지 올린 높이보다 크게 끌어도 위로는 올라가지 않는다.
        #expect(layout.offset(forVisibleHeight: 750) == 0)
    }

    @Test("멈춘 높이 단계에서 가려지는 아래쪽 높이는 최대 높이에서 그 단계 높이를 뺀 값이다")
    func hiddenHeightForDetent() {
        #expect(layout.hiddenHeight(for: .large) == 0)
        #expect(layout.hiddenHeight(for: .medium) == 300)
        #expect(layout.hiddenHeight(for: .fraction(0.25)) == 500)
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

        #expect(layout.targetDetent(releasedHeight: 520, startHeight: 400, velocity: 0, in: detents, canHide: true) == .medium)
        #expect(layout.targetDetent(releasedHeight: 580, startHeight: 400, velocity: 0, in: detents, canHide: true) == .large)
    }

    @Test("손을 뗀 속도는 초속 1,000pt마다 약 99pt만 더 가게 반영한다")
    func projectedDistanceIsShort() {
        #expect(abs(BottomSheetLayout.projectedDistance(for: 1_000) - 99) < 0.001)
        #expect(abs(BottomSheetLayout.projectedDistance(for: -2_000) + 198) < 0.001)
    }

    @Test("튕기면 속도만큼 더 간 높이에서 가장 가까운 단계에 멈춘다")
    func flickMovesTowardVelocity() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 450, startHeight: 400, velocity: -2_000, in: detents, canHide: true) == .large)
        #expect(layout.targetDetent(releasedHeight: 650, startHeight: 700, velocity: 2_000, in: detents, canHide: true) == .medium)
    }

    @Test("끝까지 올린 시트를 살짝 튕겨 내리면 숨지 않고 가운데 단계에 멈춘다")
    func shortFlickFromTopStopsAtMedium() {
        let detents = layout.sortedDetents([.medium, .large])

        // 700에서 60pt 내리고 초속 2,500pt로 놓은 경우. 예상 높이는 약 392.5다.
        #expect(layout.targetDetent(releasedHeight: 640, startHeight: 700, velocity: 2_500, in: detents, canHide: true) == .medium)
    }

    @Test("짧게 튕겨도 튕긴 방향으로 한 단계 간다")
    func shortFlickMovesOneStep() {
        let detents = layout.sortedDetents([.medium, .large])

        // 700에서 80pt만 내리고 초속 700pt로 놓은 경우. 예상 높이(약 551)는 가운데(550)보다 위지만 가운데 단계로 간다.
        #expect(layout.targetDetent(releasedHeight: 620, startHeight: 700, velocity: 700, in: detents, canHide: true) == .medium)
        // 400에서 50pt만 올리고 초속 500pt로 놓으면 끝까지 올라간다.
        #expect(layout.targetDetent(releasedHeight: 450, startHeight: 400, velocity: -500, in: detents, canHide: true) == .large)
    }

    @Test("느리게 놓으면 가장 가까운 단계에 멈추고, 맨 위에서 위로 튕기면 그대로 멈춘다")
    func slowReleaseOrFlickPastTopStaysNearest() {
        let detents = layout.sortedDetents([.medium, .large])

        // 기준 속도보다 느리면 예상 높이에서 가장 가까운 단계다.
        #expect(layout.targetDetent(releasedHeight: 620, startHeight: 700, velocity: 150, in: detents, canHide: true) == .large)
        // 맨 위 단계에서 위로 튕기면 더 갈 단계가 없다.
        #expect(layout.targetDetent(releasedHeight: 700, startHeight: 700, velocity: -800, in: detents, canHide: true) == .large)
    }

    @Test("가장 낮은 단계에서 아래로 튕기면 숨길 수 있을 때만 숨긴다")
    func flickDownFromLowestHidesOnlyWhenAllowed() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 380, startHeight: 400, velocity: 800, in: detents, canHide: true) == nil)
        #expect(layout.targetDetent(releasedHeight: 380, startHeight: 400, velocity: 800, in: detents, canHide: false) == .medium)
    }

    @Test("다른 단계를 막 지나쳐 튕겨도 그 단계를 건너뛰지 않는다")
    func flickPastDetentDoesNotSkipIt() {
        let detents = layout.sortedDetents([.fraction(0.3), .medium, .large])

        // 700에서 끌어 가운데(400)를 조금 지난 395에서 초속 400pt로 놓으면, 예상 높이(약 355)에서 가까운 가운데에 멈춘다.
        #expect(layout.targetDetent(releasedHeight: 395, startHeight: 700, velocity: 400, in: detents, canHide: true) == .medium)
    }

    @Test("가장 낮은 단계에서 세게 튕겨 내리면 숨긴다")
    func strongFlickFromLowestDetentHides() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 400, startHeight: 400, velocity: 3_000, in: detents, canHide: true) == nil)
    }

    @Test("숨길 수 있으면 가장 낮은 단계의 절반보다 아래에서 숨긴다")
    func hidesBelowHalfOfLowestDetent() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 199, startHeight: 400, velocity: 0, in: detents, canHide: true) == nil)
        #expect(layout.targetDetent(releasedHeight: 201, startHeight: 400, velocity: 0, in: detents, canHide: true) == .medium)
    }

    @Test("숨길 수 없으면 아무리 내려도 가장 낮은 단계에 멈춘다")
    func staysAtLowestDetentWhenCannotHide() {
        let detents = layout.sortedDetents([.medium, .large])

        #expect(layout.targetDetent(releasedHeight: 0, startHeight: 400, velocity: 3_000, in: detents, canHide: false) == .medium)
    }

    @Test("목록에 없는 높이에서 놓아도 가까운 단계에 멈춘다")
    func unknownHeightSnapsToNearestDetent() {
        let detents = layout.sortedDetents([.medium, .large])
        let releasedHeight = layout.height(for: .height(450))

        #expect(layout.targetDetent(releasedHeight: releasedHeight, startHeight: 400, velocity: 0, in: detents, canHide: true) == .medium)
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
