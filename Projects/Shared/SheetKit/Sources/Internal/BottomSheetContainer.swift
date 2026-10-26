import SwiftUI

/// 시트를 붙인 뷰 위에 하단 시트를 그리고, 끌어서 높이를 바꾼다.
///
/// 손잡이 줄, 내용이 터치를 받지 않는 빈 곳, `bottomSheetDragHandle(_:)`로 지정한 뷰를 끌면 시트가 움직인다.
/// 목록(스크롤뷰, `List`)에는 시트 제스처를 붙이지 않으므로, 목록 위에서 시작한 끌기는 목록만 스크롤한다.
///
/// 시트는 늘 가장 큰 높이(`.large`)로 배치하고, 보일 높이만큼만 화면에 올라오도록 아래로 내려(`offset`) 그린다.
/// 끄는 동안과 높이 단계를 옮기는 애니메이션 동안에는 내리는 거리만 바뀌므로, 시트 안 목록을 다시 배치하지 않는다.
/// 화면 밖으로 나간 아래쪽 높이는 멈춘 뒤에 한 번만 내용의 아래 safe area로 넘긴다.
struct BottomSheetContainer<Content: View>: View {
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
    /// 손잡이 줄, 배경, 지정한 뷰의 끌기를 받는 통로. 같은 객체를 계속 써서 내용이 매 프레임 다시 갱신되지 않게 한다.
    @State private var sink = BottomSheetDragSink()
    /// 시트 안 내용에 넘기는 아래 safe area. 화면 밖으로 나가 가려진 시트 아래쪽 높이다.
    /// 높이 단계가 바뀌어도 시트가 움직이는 동안에는 바꾸지 않고, 움직임이 끝난 뒤 애니메이션 없이 한 번만 바꾼다.
    /// 움직이는 도중에 바꾸면 내용이 시트와 따로 움직였다(내려놓을 때는 아래로, 올려놓을 때는 위로 튀었다가 따라왔다).
    @State private var contentBottomInset: CGFloat = 0

    var body: some View {
        let layout = BottomSheetLayout(containerHeight: containerHeight, topInset: topInset)
        let targetBottomInset = detent.map { layout.hiddenHeight(for: $0) } ?? 0

        // 시트는 GeometryReader 클로저 밖에서 그린다.
        // 클로저 안에서 그리면, 상위 뷰 구조에 따라 바인딩이 바뀌어도 클로저가 다시 실행되지 않아 시트가 나타나지 않는다.
        return Color.clear
            .overlay(alignment: .bottom) {
                if let detent, containerHeight > 0 {
                    sheet(detent: detent, layout: layout)
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
                            // 부동소수점 오차만큼만 다른 높이는 받지 않는다. 받으면 시트 높이가 바뀌고, 그 높이로 위치를 정한
                            // 바깥 뷰가 다시 이 높이를 끝자리만큼 바꾸는 고리가 생겨 레이아웃이 끝없이 반복될 수 있다.
                            guard BottomSheetMetrics.isMeaningfulChange(from: containerHeight, to: height) else { return }
                            containerHeight = height
                        }
                }
            }
            // 시트 높이를 바깥(`onBottomSheetGeometryChange`)에 알린다. 숨으면 0이다.
            // 아래 `.animation`보다 안쪽에 둬야 높이 단계가 바뀔 때 중간 높이까지 알린다.
            .modifier(
                BottomSheetGeometryReporter(
                    height: detent.map { sheetHeight(detent: $0, layout: layout) } ?? 0,
                    maxHeight: layout.maxHeight,
                    isActive: containerHeight > 0
                )
            )
            .onChange(of: isGrabberDragging) { _, isDragging in
                guard !isDragging else { return }
                dragAbandoned(source: .grabber)
            }
            .onChange(of: isBackgroundDragging) { _, isDragging in
                guard !isDragging else { return }
                dragAbandoned(source: .background)
            }
            // 시트가 커지든 작아지든 움직임이 끝난 뒤에 애니메이션 없이 바꾼다.
            // 움직이는 도중에 바꾸면 커질 때는 내용이 위로, 작아질 때는 아래로 튀었다.
            // 기다리는 동안 여백이 커도 셀은 시트 아래쪽까지 그려져서 빈 곳은 보이지 않는다.
            .task(id: targetBottomInset) {
                try? await Task.sleep(for: BottomSheetMetrics.settleDuration)
                guard !Task.isCancelled else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    contentBottomInset = targetBottomInset
                }
            }
            // 키보드가 올라와도 시트를 밀어 올리지 않는다.
            .ignoresSafeArea(.keyboard)
            // 높이 단계가 바뀔 때만 애니메이션을 건다. 화면이 다시 그려진다고 시트 전체에 애니메이션을 걸지 않는다.
            .animation(BottomSheetMetrics.animation, value: detent)
    }

    /// 지금 그릴 시트 높이.
    private func sheetHeight(detent: BottomSheetDetent, layout: BottomSheetLayout) -> CGFloat {
        // 이 시트를 끄는 거리에, 위에 겹친 시트들을 끄는 거리를 더한다.
        let translation = dragTranslation + linksAbove.totalTranslation
        return min(
            max(layout.height(for: detent) - translation, BottomSheetMetrics.grabberAreaHeight),
            layout.maxHeight
        )
    }

    private func sheet(detent: BottomSheetDetent, layout: BottomSheetLayout) -> some View {
        let sortedDetents = layout.sortedDetents(detents)
        let baseHeight = layout.height(for: detent)
        let visibleHeight = sheetHeight(detent: detent, layout: layout)
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: cornerRadius,
            topTrailingRadius: cornerRadius,
            style: .continuous
        )
        // 손잡이 줄, 배경, 지정한 뷰의 끌기를 모두 같은 처리로 보낸다.
        // 통로 객체는 그대로 두고 처리만 지금 상태로 바꾼다.
        let sink = sink
        sink.update(
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

        return sheetBody(
            detent: detent,
            layout: layout,
            sortedDetents: sortedDetents,
            bottomInset: contentBottomInset,
            sink: sink
        )
        // 가로 길이는 따로 계산하지 않고 시트를 붙인 뷰의 너비를 그대로 쓴다.
        // 높이는 늘 가장 큰 높이다. 끄는 동안 바뀌지 않아서 내용, 모서리 자르기, 배경을 다시 계산하지 않는다.
        .frame(maxWidth: .infinity)
        .frame(height: layout.maxHeight, alignment: .top)
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
        // 보일 높이만큼만 화면에 올라오도록 아래로 내린다. 끄는 동안에는 이 거리만 바뀐다.
        // offset은 화면을 그리는 위치와 터치 위치만 옮기고 배치는 바꾸지 않는다.
        .offset(y: layout.offset(forVisibleHeight: visibleHeight))
    }

    /// 손잡이 줄과 내용.
    private func sheetBody(
        detent: BottomSheetDetent,
        layout: BottomSheetLayout,
        sortedDetents: [BottomSheetDetent],
        bottomInset: CGFloat,
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
                // 화면 밖으로 나간 아래쪽을 safe area로 넘겨, 스크롤 끝이 보이는 영역 안에 오게 한다.
                // 시트가 멈춘 뒤에만 바뀌므로 끄는 동안과 움직이는 동안에는 내용을 다시 배치하지 않는다.
                .safeAreaPadding(.bottom, bottomInset)
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
    /// 높이 단계를 옮기는 애니메이션이 눈에 띄게 끝나는 시간. 시트 안 내용의 아래 여백을 이 뒤에 늘린다.
    static let settleDuration: Duration = .milliseconds(450)
    /// 이보다 작게 바뀐 높이는 같은 높이로 본다.
    /// 부동소수점 계산 오차(끝자리 차이)만 거르는 값이다. 실제로 끌거나 멈춘 높이는 이보다 크게 바뀌므로 그대로 전달된다.
    static let heightChangeThreshold: CGFloat = 0.01

    /// 높이가 계산 오차보다 크게 바뀌었는지.
    static func isMeaningfulChange(from old: CGFloat, to new: CGFloat) -> Bool {
        abs(new - old) > heightChangeThreshold
    }
}
