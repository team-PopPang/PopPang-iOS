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
struct BottomSheetDragSink {
    let changed: @MainActor (DragGesture.Value, BottomSheetDragSource) -> Void
    let ended: @MainActor (DragGesture.Value, BottomSheetDragSource) -> Void
    /// 제스처가 `onEnded` 없이 끝났을 때 부른다. 정상적으로 끝난 끌기면 아무 일도 하지 않는다.
    let abandoned: @MainActor (BottomSheetDragSource) -> Void
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
