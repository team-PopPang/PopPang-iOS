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

    /// 최대 높이로 그린 시트를 아래로 내릴 거리. 시트는 이만큼 화면 밖으로 나가고 `visibleHeight`만큼 보인다.
    ///
    /// 끄는 동안에는 시트 크기를 바꾸지 않고 이 거리만 바꾼다. 크기를 바꾸면 시트 안 목록이 매 프레임 다시 배치된다.
    func offset(forVisibleHeight visibleHeight: CGFloat) -> CGFloat {
        max(maxHeight - visibleHeight, 0)
    }

    /// 높이 단계에 멈췄을 때 화면 밖으로 나가 가려지는 시트 아래쪽 높이.
    /// 시트 안 내용의 아래 safe area로 넘겨서, 스크롤 끝이 보이는 영역 안에 오게 한다.
    func hiddenHeight(for detent: BottomSheetDetent) -> CGFloat {
        offset(forVisibleHeight: height(for: detent))
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

    /// 이보다 빠르게 놓으면 튕긴 것으로 보고, 튕긴 방향으로 적어도 한 단계 간다. 단위는 초당 pt다.
    ///
    /// 예상 높이만 보면, 끝까지 올린 시트를 짧고 빠르게 튕겨 내렸을 때 두 단계의 가운데를 넘지 못해 다시 위로 돌아갔다.
    /// 손가락은 떼기 직전에 느려져서, 300으로 두었을 때는 80pt를 0.12초에 튕겨도 초속 288pt로 잡혀 다시 올라갔다.
    static let flickVelocity: CGFloat = 200

    /// 손을 뗐을 때 멈출 단계. 숨겨야 하면 `nil`이다.
    ///
    /// 손을 뗀 높이에서 속도로 더 움직일 거리만큼 옮긴 예상 높이를 구하고, 그 높이에서 가장 가까운 단계를 고른다.
    /// 숨길 수 있으면 높이 0을 숨김 단계로 보고, 가장 낮은 단계의 절반보다 아래면 숨긴다.
    /// `flickVelocity`보다 빠르게 놓았는데 고른 단계가 끌기 전 단계면, 끌기 전 단계에서 튕긴 방향으로 한 단계 간다.
    /// 가장 낮은 단계에서 아래로 튕기면 숨길 수 있을 때 숨긴다.
    ///
    /// 한 단계는 손을 뗀 높이가 아니라 끌기 전 단계에서 센다. 손을 뗀 높이에서 세면, 다른 단계를 막 지나쳐 놓았을 때
    /// 그 단계를 건너뛰고 하나 더 갔다.
    ///
    /// - Parameters:
    ///   - releasedHeight: 손을 뗀 순간의 시트 높이.
    ///   - startHeight: 끌기 전에 멈춰 있던 높이.
    ///   - velocity: 손을 뗀 순간의 초당 이동 거리. 아래로 끌면 양수다.
    func targetDetent(
        releasedHeight: CGFloat,
        startHeight: CGFloat,
        velocity: CGFloat,
        in sortedDetents: [BottomSheetDetent],
        canHide: Bool
    ) -> BottomSheetDetent? {
        guard let lowest = sortedDetents.first else { return nil }
        let projectedHeight = releasedHeight - Self.projectedDistance(for: velocity)
        if canHide, projectedHeight < height(for: lowest) / 2 {
            return nil
        }
        let nearest = sortedDetents.min {
            abs(height(for: $0) - projectedHeight) < abs(height(for: $1) - projectedHeight)
        }
        guard abs(velocity) >= Self.flickVelocity,
              let nearest,
              !BottomSheetMetrics.isMeaningfulChange(from: height(for: nearest), to: startHeight)
        else { return nearest }

        // 끌기 전 단계로 돌아가려 하면, 튕긴 방향으로 끌기 전 단계 바로 다음 단계로 간다.
        if velocity > 0 {
            let lower = sortedDetents.last { height(for: $0) < startHeight }
            if let lower { return lower }
            // 가장 낮은 단계에서 아래로 튕겼다.
            return canHide ? nil : nearest
        }
        return sortedDetents.first { height(for: $0) > startHeight } ?? nearest
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
