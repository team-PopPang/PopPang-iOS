import SwiftUI

/// 시트를 붙인 뷰 위에 하단 시트를 그리고, 끌어서 높이를 바꾼다.
///
/// 손잡이 줄, 내용이 터치를 받지 않는 빈 곳, `bottomSheetDragHandle(_:)`로 지정한 뷰를 끌면 시트가 움직인다.
/// 목록(스크롤뷰, `List`)에는 시트 제스처를 붙이지 않으므로, 목록 위에서 시작한 끌기는 목록만 스크롤한다.
struct BottomSheetContainer<Content: View, Accessory: View>: View {
    /// 지금 높이 단계. `nil`이면 시트를 숨긴다.
    let detent: BottomSheetDetent?
    let detents: Set<BottomSheetDetent>
    /// 가장 낮은 단계보다 아래로 끌어 숨길 수 있는지.
    let canHide: Bool
    /// 이 시트를 끄는 거리를 아래 시트(먼저 붙인 시트)에 알려 주는 연결.
    let link: BottomSheetLink
    /// 손잡이로 높이 단계를 바꿀 때 부른다. 숨기면 `nil`을 넘긴다.
    let setDetent: (BottomSheetDetent?) -> Void
    let content: Content
    /// 시트 위쪽 끝에 붙어 시트와 같이 움직이는 뷰. 없으면 `EmptyView`다.
    let accessory: Accessory

    @Environment(\.bottomSheetTopInset) private var topInset
    @Environment(\.bottomSheetBackground) private var background
    @Environment(\.bottomSheetCornerRadius) private var cornerRadius
    /// 이 시트 위에 겹친 시트(나중에 붙인 시트)들의 연결.
    /// 그 시트들을 끄는 동안 이 시트도 같은 거리만큼 같이 움직인다.
    @Environment(\.bottomSheetLinksAbove) private var linksAbove
    /// 시트를 움직이고 있는 끌기. 손잡이 줄, 배경, 지정한 뷰 가운데 먼저 시작한 한 곳만 따른다.
    @State private var drag: BottomSheetDrag?
    /// 끄는 동안 움직인 거리.
    /// 끄는 동안에는 시트 안에서만 높이를 바꾸고, 손을 뗄 때 한 번만 `detent`를 바꾼다.
    @State private var dragTranslation: CGFloat = 0
    /// 손잡이 줄과 배경의 끌기가 진행 중인지.
    /// 끌기가 `onEnded` 없이 끊기면(알림 센터를 내리거나 앱이 백그라운드로 갈 때) 원래 높이로 되돌리는 데 쓴다.
    @GestureState private var isGrabberDragging = false
    @GestureState private var isBackgroundDragging = false
    /// 시트를 붙인 뷰의 높이.
    @State private var containerHeight: CGFloat = 0

    var body: some View {
        // 시트는 GeometryReader 클로저 밖에서 그린다.
        // 클로저 안에서 그리면, 상위 뷰 구조에 따라 바인딩이 바뀌어도 클로저가 다시 실행되지 않아 시트가 나타나지 않는다.
        Color.clear
            .overlay(alignment: .bottom) {
                if let detent, containerHeight > 0 {
                    sheet(
                        detent: detent,
                        layout: BottomSheetLayout(containerHeight: containerHeight, topInset: topInset)
                    )
                    .transition(.move(edge: .bottom))
                }
            }
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            containerHeight = proxy.size.height
                        }
                        .onChange(of: proxy.size.height) { _, height in
                            containerHeight = height
                        }
                }
            }
            .onChange(of: isGrabberDragging) { _, isDragging in
                guard !isDragging else { return }
                dragAbandoned(source: .grabber)
            }
            .onChange(of: isBackgroundDragging) { _, isDragging in
                guard !isDragging else { return }
                dragAbandoned(source: .background)
            }
            // 키보드가 올라와도 시트를 밀어 올리지 않는다.
            .ignoresSafeArea(.keyboard)
            // 높이 단계가 바뀔 때만 애니메이션을 건다. 화면이 다시 그려진다고 시트 전체에 애니메이션을 걸지 않는다.
            .animation(BottomSheetMetrics.animation, value: detent)
    }

    private func sheet(detent: BottomSheetDetent, layout: BottomSheetLayout) -> some View {
        let sortedDetents = layout.sortedDetents(detents)
        let baseHeight = layout.height(for: detent)
        // 이 시트를 끄는 거리에, 위에 겹친 시트들을 끄는 거리를 더한다.
        let translation = dragTranslation + linksAbove.totalTranslation
        let height = min(
            max(baseHeight - translation, BottomSheetMetrics.grabberAreaHeight),
            layout.maxHeight
        )
        let accessoryOpacity = layout.accessoryOpacity(sheetHeight: height, in: sortedDetents)
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: cornerRadius,
            topTrailingRadius: cornerRadius,
            style: .continuous
        )
        // 손잡이 줄, 배경, 지정한 뷰의 끌기를 모두 같은 처리로 보낸다.
        let sink = BottomSheetDragSink(
            changed: { value, source in
                dragChanged(value, source: source)
            },
            ended: { value, source in
                dragEnded(
                    value,
                    source: source,
                    layout: layout,
                    sortedDetents: sortedDetents,
                    baseHeight: baseHeight
                )
            },
            abandoned: { source in
                dragAbandoned(source: source)
            }
        )

        return VStack(spacing: 0) {
            // 액세서리는 시트 위쪽 끝에 붙여 같은 높이 값으로 그린다.
            // 시트를 붙인 화면이 매 프레임 시트 위치를 받아 다시 그리지 않아도 시트와 같은 프레임에 움직인다.
            accessory
                .opacity(accessoryOpacity)
                .allowsHitTesting(accessoryOpacity > 0)
                .accessibilityHidden(accessoryOpacity == 0)

            sheetBody(
                detent: detent,
                layout: layout,
                sortedDetents: sortedDetents,
                sink: sink
            )
            // 가로 길이는 따로 계산하지 않고 시트를 붙인 뷰의 너비를 그대로 쓴다.
            .frame(maxWidth: .infinity)
            .frame(height: height, alignment: .top)
            .clipShape(shape)
            .background {
                // 내용은 safe area 안에 두고, 배경만 탭바와 홈 인디케이터 아래 화면 끝까지 깐다.
                // 내용이 터치를 받지 않는 빈 곳(여백, Spacer)을 끌어도 시트가 움직이도록 배경에 끌기를 붙인다.
                // 배경 색이 투명해도 잡히도록 모양으로 판정한다.
                shape
                    .fill(background)
                    .contentShape(shape)
                    .gesture(dragGesture(source: .background, isActive: $isBackgroundDragging, sink: sink))
                    .ignoresSafeArea(.container, edges: .bottom)
            }
        }
    }

    /// 손잡이 줄과 내용.
    private func sheetBody(
        detent: BottomSheetDetent,
        layout: BottomSheetLayout,
        sortedDetents: [BottomSheetDetent],
        sink: BottomSheetDragSink
    ) -> some View {
        VStack(spacing: 0) {
            BottomSheetGrabber(
                onTap: {
                    setDetent(layout.detentAfterTap(from: detent, in: sortedDetents))
                },
                onIncrement: {
                    setDetent(layout.detentAfterIncrement(from: detent, in: sortedDetents))
                },
                onDecrement: {
                    setDetent(
                        layout.detentAfterDecrement(
                            from: detent,
                            in: sortedDetents,
                            canHide: canHide
                        )
                    )
                }
            )
            .gesture(dragGesture(source: .grabber, isActive: $isGrabberDragging, sink: sink))

            content
                // 내용 안의 `bottomSheetDragHandle(_:)`이 끌기를 넘길 통로.
                .environment(\.bottomSheetDragSink, sink)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func dragGesture(
        source: BottomSheetDragSource,
        isActive: GestureState<Bool>,
        sink: BottomSheetDragSink
    ) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating(isActive) { _, isActive, _ in
                isActive = true
            }
            .onChanged { value in
                sink.changed(value, source)
            }
            .onEnded { value in
                sink.ended(value, source)
            }
    }

    private func dragChanged(_ value: DragGesture.Value, source: BottomSheetDragSource) {
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

        dragTranslation = value.translation.height
        // 아래 시트가 같은 프레임에 같이 움직이도록 끄는 거리를 바로 알린다.
        link.translation = value.translation.height
    }

    private func dragEnded(
        _ value: DragGesture.Value,
        source: BottomSheetDragSource,
        layout: BottomSheetLayout,
        sortedDetents: [BottomSheetDetent],
        baseHeight: CGFloat
    ) {
        guard let current = drag, current.source == source else { return }
        drag = nil
        guard !current.isHorizontal else { return }

        // `predictedEndTranslation`은 너무 멀리 예측하므로 속도는 `BottomSheetLayout`이 짧게 반영한다.
        let target = layout.targetDetent(
            releasedHeight: baseHeight - value.translation.height,
            velocity: value.velocity.height,
            in: sortedDetents,
            canHide: canHide
        )
        withAnimation(BottomSheetMetrics.animation) {
            dragTranslation = 0
            link.translation = 0
            setDetent(target)
        }
    }

    /// 제스처가 `onEnded` 없이 끊겼을 때 원래 높이로 되돌린다.
    /// 정상적으로 끝난 끌기는 `onEnded`가 먼저 상태를 비우므로 아무 일도 하지 않는다.
    private func dragAbandoned(source: BottomSheetDragSource) {
        guard let current = drag, current.source == source else { return }
        drag = nil

        withAnimation(BottomSheetMetrics.animation) {
            dragTranslation = 0
            link.translation = 0
        }
    }
}

/// 시트 위쪽의 손잡이 줄. 줄 전체를 잡고 끌 수 있다.
struct BottomSheetGrabber: View {
    let onTap: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void

    var body: some View {
        Capsule()
            .fill(Color(uiColor: .tertiaryLabel))
            .frame(
                width: BottomSheetMetrics.grabberSize.width,
                height: BottomSheetMetrics.grabberSize.height
            )
            .frame(maxWidth: .infinity)
            .frame(height: BottomSheetMetrics.grabberAreaHeight)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTap)
            .accessibilityElement()
            .accessibilityLabel(Text("bottomSheet.grabber.label", bundle: .module))
            .accessibilityHint(Text("bottomSheet.grabber.hint", bundle: .module))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onTap() }
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    onIncrement()
                case .decrement:
                    onDecrement()
                @unknown default:
                    break
                }
            }
    }
}

enum BottomSheetMetrics {
    static let grabberSize = CGSize(width: 36, height: 5)
    /// 손잡이 줄의 높이. 시트를 끝까지 끌어 내려도 이 높이는 남는다.
    static let grabberAreaHeight: CGFloat = 20
    static let animation = Animation.spring(response: 0.4, dampingFraction: 0.85)
}
