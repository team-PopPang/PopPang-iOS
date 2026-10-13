import CoreGraphics

/// 높이 단계를 실제 높이로 바꾸고, 시트를 움직였을 때 갈 단계를 고른다.
///
/// 화면과 관계없는 계산만 모아서 테스트할 수 있게 둔다.
struct BottomSheetLayout {
    /// 시트를 붙인 뷰의 높이.
    let containerHeight: CGFloat
    /// 시트를 끝까지 올렸을 때 위에 남길 공간.
    let topInset: CGFloat

    /// 시트가 가질 수 있는 가장 큰 높이.
    var maxHeight: CGFloat {
        max(containerHeight - topInset, 0)
    }

    func height(for detent: BottomSheetDetent) -> CGFloat {
        let height: CGFloat = switch detent.kind {
        case .fraction(let value):
            containerHeight * value
        case .height(let value):
            value
        case .large:
            maxHeight
        }
        return min(max(height, 0), maxHeight)
    }

    /// 높이가 낮은 순서로 정렬한 단계. 단계가 없으면 `.large` 하나만 쓴다.
    func sortedDetents(_ detents: Set<BottomSheetDetent>) -> [BottomSheetDetent] {
        let detents = detents.isEmpty ? [.large] : detents
        return detents.sorted { height(for: $0) < height(for: $1) }
    }

    /// 손을 뗐을 때 멈출 단계. 숨겨야 하면 `nil`이다.
    ///
    /// 손을 뗀 위치에 속도를 반영한 예상 높이(`projectedHeight`)에서 가장 가까운 단계를 고른다.
    /// 숨길 수 있으면 높이 0을 숨김 단계로 보고, 가장 낮은 단계의 절반보다 아래면 숨긴다.
    func targetDetent(
        projectedHeight: CGFloat,
        in sortedDetents: [BottomSheetDetent],
        canHide: Bool
    ) -> BottomSheetDetent? {
        guard let lowest = sortedDetents.first else { return nil }
        if canHide, projectedHeight < height(for: lowest) / 2 {
            return nil
        }
        return sortedDetents.min {
            abs(height(for: $0) - projectedHeight) < abs(height(for: $1) - projectedHeight)
        }
    }

    /// 손잡이를 눌렀을 때 갈 단계. 위로 한 단계 가고, 맨 위에서는 아래로 한 단계 간다.
    func detentAfterTap(
        from current: BottomSheetDetent,
        in sortedDetents: [BottomSheetDetent]
    ) -> BottomSheetDetent {
        higherDetent(than: current, in: sortedDetents)
            ?? lowerDetent(than: current, in: sortedDetents)
            ?? current
    }

    /// VoiceOver로 높이를 올렸을 때 갈 단계. 맨 위면 그대로 둔다.
    func detentAfterIncrement(
        from current: BottomSheetDetent,
        in sortedDetents: [BottomSheetDetent]
    ) -> BottomSheetDetent {
        higherDetent(than: current, in: sortedDetents) ?? current
    }

    /// VoiceOver로 높이를 내렸을 때 갈 단계. 맨 아래에서 숨길 수 있으면 `nil`, 숨길 수 없으면 그대로 둔다.
    func detentAfterDecrement(
        from current: BottomSheetDetent,
        in sortedDetents: [BottomSheetDetent],
        canHide: Bool
    ) -> BottomSheetDetent? {
        if let lower = lowerDetent(than: current, in: sortedDetents) {
            return lower
        }
        return canHide ? nil : current
    }

    private func higherDetent(
        than current: BottomSheetDetent,
        in sortedDetents: [BottomSheetDetent]
    ) -> BottomSheetDetent? {
        let currentHeight = height(for: current)
        return sortedDetents.first { height(for: $0) > currentHeight }
    }

    private func lowerDetent(
        than current: BottomSheetDetent,
        in sortedDetents: [BottomSheetDetent]
    ) -> BottomSheetDetent? {
        let currentHeight = height(for: current)
        return sortedDetents.last { height(for: $0) < currentHeight }
    }
}
