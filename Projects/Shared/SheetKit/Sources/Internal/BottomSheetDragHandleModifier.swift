import SwiftUI

/// 지정한 뷰에 시트를 끄는 제스처를 붙인다.
struct BottomSheetDragHandleModifier: ViewModifier {
    let isEnabled: Bool

    @Environment(\.bottomSheetDragSink) private var sink
    /// 손잡이로 지정한 뷰마다 다른 이름. 두 손가락이 서로 다른 뷰를 끌 때 어느 끌기인지 구분한다.
    @State private var id = UUID()
    /// 끌기가 진행 중인지. `onEnded` 없이 끊긴 끌기(알림 센터, 앱 전환)를 알아채는 데 쓴다.
    @GestureState private var isDragging = false

    func body(content: Content) -> some View {
        let source = BottomSheetDragSource.handle(id)
        let sink = sink

        content
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .updating($isDragging) { _, isDragging, _ in
                        isDragging = true
                    }
                    .onChanged { value in
                        sink?.changed(value, source)
                    }
                    .onEnded { value in
                        sink?.ended(value, source)
                    },
                // 시트 밖이거나 끈 상태면 이 제스처만 끄고 안쪽 버튼의 제스처는 살린다.
                // 수정자를 떼지 않고 마스크로 꺼야 뷰의 상태가 유지된다.
                including: isEnabled && sink != nil ? .all : .subviews
            )
            .onChange(of: isDragging) { _, isDragging in
                guard !isDragging else { return }
                sink?.abandoned(source)
            }
            // 끄는 도중 뷰가 사라지면 `onChange`가 오지 않을 수 있다.
            .onDisappear {
                sink?.abandoned(source)
            }
    }
}

/// 지정한 뷰의 끌기를 시트에 넘기는 통로. 시트가 내용에 environment로 넣는다.
///
/// 시트마다 하나만 만들고 같은 객체를 계속 넘긴다. 시트가 다시 그려질 때 처리 클로저만 바꾼다.
/// 값(struct)으로 매번 새로 만들면, 클로저는 비교할 수 없어 SwiftUI가 environment가 바뀐 것으로 보고
/// 끄는 동안 매 프레임 시트 안 모든 뷰를 다시 갱신했다.
@MainActor
final class BottomSheetDragSink {
    private(set) var changed: (DragGesture.Value, BottomSheetDragSource) -> Void = { _, _ in }
    private(set) var ended: (DragGesture.Value, BottomSheetDragSource) -> Void = { _, _ in }
    /// 제스처가 `onEnded` 없이 끝났을 때 부른다. 정상적으로 끝난 끌기면 아무 일도 하지 않는다.
    private(set) var abandoned: (BottomSheetDragSource) -> Void = { _ in }

    /// 처리 클로저를 지금 시트 상태로 바꾼다. 객체는 그대로라 environment를 읽는 뷰는 다시 갱신되지 않는다.
    func update(
        changed: @escaping (DragGesture.Value, BottomSheetDragSource) -> Void,
        ended: @escaping (DragGesture.Value, BottomSheetDragSource) -> Void,
        abandoned: @escaping (BottomSheetDragSource) -> Void
    ) {
        self.changed = changed
        self.ended = ended
        self.abandoned = abandoned
    }
}

private struct BottomSheetDragSinkKey: EnvironmentKey {
    static var defaultValue: BottomSheetDragSink? { nil }
}

extension EnvironmentValues {
    /// 가장 가까운 시트의 끌기 통로. 시트 밖에서는 `nil`이다.
    var bottomSheetDragSink: BottomSheetDragSink? {
        get { self[BottomSheetDragSinkKey.self] }
        set { self[BottomSheetDragSinkKey.self] = newValue }
    }
}
