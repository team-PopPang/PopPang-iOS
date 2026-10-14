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

    /// 손을 뗀 속도로 시트가 더 움직일 거리를 줄이는 정도.
    ///
    /// `UIScrollView`의 기본값 0.998은 화면 몇 개만큼 미끄러지도록 맞춘 값이다.
    /// SwiftUI `DragGesture`의 `predictedEndTranslation`도 그만큼 멀리 예측해서, 끝까지 올린 시트를 살짝 튕겨도
    /// 중간 단계를 건너뛰고 숨었다. 값을 낮춰 손을 뗀 위치가 주도권을 갖고 속도는 거들기만 하게 한다.
    static let decelerationRate: CGFloat = 0.99

    /// 손을 뗀 속도로 시트가 더 움직일 거리. 아래로 끌면 양수다.
    ///
    /// 초속 1,000pt로 놓으면 약 99pt 더 간다.
    static func projectedDistance(for velocity: CGFloat) -> CGFloat {
        velocity / 1000 * decelerationRate / (1 - decelerationRate)
    }

    /// 손을 뗐을 때 멈출 단계. 숨겨야 하면 `nil`이다.
    ///
    /// 손을 뗀 높이에서 속도로 더 움직일 거리만큼 옮긴 예상 높이를 구하고, 그 높이에서 가장 가까운 단계를 고른다.
    /// 숨길 수 있으면 높이 0을 숨김 단계로 보고, 가장 낮은 단계의 절반보다 아래면 숨긴다.
    ///
    /// - Parameters:
    ///   - releasedHeight: 손을 뗀 순간의 시트 높이.
    ///   - velocity: 손을 뗀 순간의 초당 이동 거리. 아래로 끌면 양수다.
    func targetDetent(
        releasedHeight: CGFloat,
        velocity: CGFloat,
        in sortedDetents: [BottomSheetDetent],
        canHide: Bool
    ) -> BottomSheetDetent? {
        guard let lowest = sortedDetents.first else { return nil }
        let projectedHeight = releasedHeight - Self.projectedDistance(for: velocity)
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
