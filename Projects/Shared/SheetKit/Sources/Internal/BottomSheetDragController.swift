import Observation
import SwiftUI

/// 시트 하나의 끌기 상태와 처리.
///
/// 손잡이 줄, 배경, `bottomSheetDragHandle(_:)`로 지정한 뷰의 끌기가 모두 이 객체로 온다. 시트 안 내용에도 environment로
/// 넘기므로 시트마다 하나만 만들고 같은 객체를 계속 쓴다. 값으로 매번 새로 만들면 SwiftUI가 같은 값인지 비교할 수 없어,
/// 끄는 동안 매 프레임 시트 안 모든 뷰를 다시 갱신했다.
///
/// 끌기를 끝낼 때 필요한 값(높이 계산, 높이 단계, 단계를 바꾸는 방법)은 시트를 그릴 때마다 `configuration`에 값으로 넣는다.
/// 이 객체는 시트 뷰를 붙잡지 않으므로, 시트 뷰가 `@State`로 이 객체를 붙잡아도 순환 참조가 생기지 않는다.
@MainActor
@Observable
final class BottomSheetDragController {
    struct Configuration {
        var layout: BottomSheetLayout
        var sortedDetents: [BottomSheetDetent]
        /// 끌기 전에 멈춰 있던 높이.
        var baseHeight: CGFloat
        /// 가장 낮은 단계보다 아래로 끌어 숨길 수 있는지.
        var canHide: Bool
        /// 이 시트를 끄는 거리를 아래 시트에 알려 주는 연결.
        var link: BottomSheetLink
        /// 손을 뗀 뒤 멈출 높이 단계를 정한다. 숨기면 `nil`을 넘긴다.
        var setDetent: (BottomSheetDetent?) -> Void
    }

    /// 시트를 움직이고 있는 끌기. 손잡이 줄, 배경, 지정한 뷰 가운데 먼저 시작한 한 곳만 따른다.
    private(set) var drag: BottomSheetDrag?
    /// 끄는 동안 움직인 거리.
    /// 끄는 동안에는 시트 안에서만 위치를 바꾸고, 손을 뗄 때 한 번만 높이 단계를 바꾼다.
    private(set) var translation: CGFloat = 0
    /// 시트를 그릴 때마다 지금 값으로 바꾼다. 화면을 다시 그리게 하는 값이 아니어서 관찰하지 않는다.
    @ObservationIgnored var configuration: Configuration?

    func changed(_ value: DragGesture.Value, source: BottomSheetDragSource) {
        let current: BottomSheetDrag
        switch BottomSheetDrag.decision(for: source, current: drag) {
        case .ignore:
            return
        case .begin:
            current = BottomSheetDrag(source: source, isHorizontal: BottomSheetDrag.isHorizontal(value.translation))
            drag = current
        case .follow:
            guard let drag else { return }
            current = drag
        }
        guard !current.isHorizontal else { return }

        translation = value.translation.height
        // 아래 시트가 같은 프레임에 같이 움직이도록 끄는 거리를 바로 알린다.
        configuration?.link.translation = value.translation.height
    }

    func ended(_ value: DragGesture.Value, source: BottomSheetDragSource) {
        guard let current = drag, current.source == source else { return }
        drag = nil
        guard !current.isHorizontal, let configuration else { return }

        // `predictedEndTranslation`은 너무 멀리 예측하므로 속도는 `BottomSheetLayout`이 짧게 반영한다.
        let target = configuration.layout.targetDetent(
            releasedHeight: configuration.baseHeight - value.translation.height,
            velocity: value.velocity.height,
            in: configuration.sortedDetents,
            canHide: configuration.canHide
        )
        withAnimation(BottomSheetMetrics.animation) {
            translation = 0
            configuration.link.translation = 0
            configuration.setDetent(target)
        }
    }

    /// 제스처가 `onEnded` 없이 끊겼을 때 원래 높이로 되돌린다.
    /// 정상적으로 끝난 끌기는 `ended`가 먼저 상태를 비우므로 아무 일도 하지 않는다.
    func abandoned(source: BottomSheetDragSource) {
        guard let current = drag, current.source == source else { return }
        drag = nil

        withAnimation(BottomSheetMetrics.animation) {
            translation = 0
            configuration?.link.translation = 0
        }
    }
}

private struct BottomSheetDragControllerKey: EnvironmentKey {
    static var defaultValue: BottomSheetDragController? { nil }
}

extension EnvironmentValues {
    /// 가장 가까운 시트의 끌기 처리. 시트 밖에서는 `nil`이다.
    var bottomSheetDragController: BottomSheetDragController? {
        get { self[BottomSheetDragControllerKey.self] }
        set { self[BottomSheetDragControllerKey.self] = newValue }
    }
}
