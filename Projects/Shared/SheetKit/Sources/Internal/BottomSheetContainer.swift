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
    /// 끌기 상태와 처리. 손잡이 줄, 배경, 지정한 뷰의 끌기가 모두 여기로 온다.
    @State private var dragController = BottomSheetDragController()
    /// 손잡이 줄과 배경의 끌기가 진행 중인지.
    /// 끌기가 `onEnded` 없이 끊기면(알림 센터를 내리거나 앱이 백그라운드로 갈 때) 원래 높이로 되돌리는 데 쓴다.
    @GestureState private var isGrabberDragging = false
    @GestureState private var isBackgroundDragging = false
    /// 시트를 붙인 뷰의 높이.
    @State private var containerHeight: CGFloat = 0
    /// 시트 안 내용에 넘기는 아래 safe area. 화면 밖으로 나가 가려진 시트 아래쪽 높이다.
    /// 높이 단계가 바뀌어도 시트가 움직이는 동안에는 바꾸지 않고, 움직임이 끝난 뒤 한 번만 바꾼다.
    /// 늘릴 때(시트가 작아질 때)는 애니메이션 없이, 줄일 때(시트가 커질 때)는 애니메이션으로 바꾼다.
    /// 움직이는 도중에 바꾸면 내용이 시트와 따로 움직였다(내려놓을 때는 아래로, 올려놓을 때는 위로 튀었다가 따라왔다).
    @State private var contentBottomInset: CGFloat = 0

    var body: some View {
        let layout = BottomSheetLayout(containerHeight: containerHeight, topInset: topInset)
        let insetRequest = BottomSheetInsetRequest(
            target: detent.map { layout.hiddenHeight(for: $0) } ?? 0,
            // 이 시트나 위에 겹친 시트를 끄는 중이면 이 시트가 움직이는 중이다.
            isMoving: dragController.drag != nil || linksAbove.totalTranslation != 0
        )

        // 시트는 GeometryReader 클로저 밖에서 그린다.
        // 클로저 안에서 그리면, 상위 뷰 구조에 따라 바인딩이 바뀌어도 클로저가 다시 실행되지 않아 시트가 나타나지 않는다.
        return Color.clear
            .overlay(alignment: .bottom) {
                if let detent, containerHeight > 0 {
                    sheet(detent: detent, layout: layout)
                        .transition(.move(edge: .bottom))
                        // 시트가 나타날 때는 아직 움직이는 중이 아니므로, 기다리지 않고 처음부터 가려진 높이를 넘긴다.
                        // 기다리면 그동안 내용 아래쪽이 화면 밖에 있어 목록 끝까지 스크롤할 수 없다.
                        .onAppear {
                            setContentBottomInset(layout.hiddenHeight(for: detent))
                        }
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
                dragController.abandoned(source: .grabber)
            }
            .onChange(of: isBackgroundDragging) { _, isDragging in
                guard !isDragging else { return }
                dragController.abandoned(source: .background)
            }
            // 아래 여백은 시트가 움직이지 않을 때만 바꾼다. 움직이는 도중에 바꾸면 내용이 시트와 따로 움직였다
            // (커질 때는 위로, 작아질 때는 아래로 튀었다가 따라왔다).
            // 끌기가 시작되면 `isMoving`이 바뀌어 기다리던 작업이 취소되고, 손을 떼면 그때부터 다시 기다린다.
            // 기다리는 동안 여백이 커도 셀은 시트 아래쪽까지 그려져서 빈 곳은 보이지 않는다.
            .task(id: insetRequest) {
                guard !insetRequest.isMoving else { return }
                // 손을 뗀 뒤 높이 단계를 옮기는 애니메이션이 끝나기를 기다린다.
                try? await Task.sleep(for: BottomSheetMetrics.settleDuration)
                guard !Task.isCancelled else { return }
                // 커질 때(여백이 줄 때)는 애니메이션으로 바꾼다. 목록을 끝까지 내린 상태면 스크롤 위치가 맞춰지는데,
                // 애니메이션 없이 바꾸면 그만큼 한 번에 튄다. 시트는 이미 멈춘 뒤라 내용이 시트와 따로 움직이지 않는다.
                setContentBottomInset(insetRequest.target, animated: insetRequest.target < contentBottomInset)
            }
            // 키보드가 올라와도 시트를 밀어 올리지 않는다.
            .ignoresSafeArea(.keyboard)
            // 높이 단계가 바뀔 때만 애니메이션을 건다. 화면이 다시 그려진다고 시트 전체에 애니메이션을 걸지 않는다.
            .animation(BottomSheetMetrics.animation, value: detent)
    }

    /// 시트 안 내용의 아래 safe area를 바꾼다. `animated`가 아니면 애니메이션 없이 바꾼다.
    private func setContentBottomInset(_ inset: CGFloat, animated: Bool = false) {
        guard !animated else {
            withAnimation(BottomSheetMetrics.insetAnimation) {
                contentBottomInset = inset
            }
            return
        }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            contentBottomInset = inset
        }
    }

    /// 지금 그릴 시트 높이.
    private func sheetHeight(detent: BottomSheetDetent, layout: BottomSheetLayout) -> CGFloat {
        // 이 시트를 끄는 거리에, 위에 겹친 시트들을 끄는 거리를 더한다.
        let translation = dragController.translation + linksAbove.totalTranslation
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
        // 끌기를 끝낼 때 쓸 값은 지금 상태로 넘긴다. 값만 넘겨서 처리 객체가 이 뷰를 붙잡지 않는다.
        let dragController = dragController
        dragController.configuration = BottomSheetDragController.Configuration(
            layout: layout,
            sortedDetents: sortedDetents,
            baseHeight: baseHeight,
            canHide: canHide,
            link: link,
            setDetent: setDetent
        )

        return sheetBody(
            detent: detent,
            layout: layout,
            sortedDetents: sortedDetents,
            bottomInset: contentBottomInset,
            dragController: dragController
        )
        // 가로 길이는 따로 계산하지 않고 시트를 붙인 뷰의 너비를 그대로 쓴다.
        // 높이는 늘 가장 큰 높이다. 끄는 동안 바뀌지 않아서 내용, 모서리 자르기, 배경을 다시 계산하지 않는다.
        .frame(maxWidth: .infinity)
        .frame(height: layout.maxHeight, alignment: .top)
        // 위쪽 둥근 모서리와 함께, 내용은 지금 화면에 올라와 보이는 높이까지만 그리고 터치도 그 안에서만 받는다.
        // 아래로 내린 부분을 자르지 않으면, 시트를 붙인 뷰가 아래 safe area를 지킬 때 그 아래(홈 인디케이터, 탭바 자리)에
        // 내용이 그려지고 탭도 받는다. 모양이 `Animatable`이라 높이 단계를 옮길 때 시트와 같은 애니메이션으로 움직인다.
        .clipShape(BottomSheetVisibleShape(height: visibleHeight, cornerRadius: cornerRadius))
        // clipShape는 그리기만 자르고 터치 판정은 자르지 않으므로, 터치 영역도 같은 모양으로 제한한다.
        .contentShape(BottomSheetVisibleShape(height: visibleHeight, cornerRadius: cornerRadius))
        .background {
            // 내용은 safe area 안에 두고, 배경만 탭바와 홈 인디케이터 아래 화면 끝까지 깐다.
            // 내용이 터치를 받지 않는 빈 곳(여백, Spacer)을 끌어도 시트가 움직이도록 배경에 끌기를 붙인다.
            // 배경 색이 투명해도 잡히도록 모양으로 판정한다.
            shape
                .fill(background)
                // 배경도 보이는 높이 안에서만 끌기를 받는다. 화면 밖으로 내린 부분이 아래 화면의 터치를 가로채지 않게 한다.
                .contentShape(BottomSheetVisibleShape(height: visibleHeight, cornerRadius: cornerRadius))
                .gesture(dragGesture(source: .background, isActive: $isBackgroundDragging, dragController: dragController))
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
        dragController: BottomSheetDragController
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
            .gesture(dragGesture(source: .grabber, isActive: $isGrabberDragging, dragController: dragController))

            content
                // 내용 안의 `bottomSheetDragHandle(_:)`이 끌기를 넘길 곳. 같은 객체라 내용이 매 프레임 다시 갱신되지 않는다.
                .environment(\.bottomSheetDragController, dragController)
                // 화면 밖으로 나간 아래쪽을 safe area로 넘겨, 스크롤 끝이 보이는 영역 안에 오게 한다.
                // 시트가 멈춘 뒤에만 바뀌므로 끄는 동안과 움직이는 동안에는 내용을 다시 배치하지 않는다.
                .safeAreaPadding(.bottom, bottomInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private func dragGesture(
        source: BottomSheetDragSource,
        isActive: GestureState<Bool>,
        dragController: BottomSheetDragController
    ) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating(isActive) { _, isActive, _ in
                isActive = true
            }
            .onChanged { value in
                dragController.changed(value, source: source)
            }
            .onEnded { value in
                dragController.ended(value, source: source)
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
    /// 높이 단계를 옮기는 애니메이션. 스프링이라 끄는 동안의 속도를 이어받아 출발한다.
    /// 살짝만 튕기며 멈춘다. 예전 라이브러리(BottomSheet) 값(0.5, 0.75)은 손을 뗀 속도를 이어받으면 너무 많이 출렁였다.
    /// 라이브러리의 `blendDuration: 1`은 넣지 않는다. 넣었더니 손을 떼는 순간 시트가 위로 튀었다가 몇 프레임 만에 건너뛰었다.
    static let animation = Animation.spring(response: 0.45, dampingFraction: 0.88)
    /// 시트 안 내용의 아래 여백을 줄이는 애니메이션. 여백이 튕기면 내용이 위아래로 흔들리므로 튕기지 않게 둔다.
    static let insetAnimation = Animation.spring(response: 0.4, dampingFraction: 1)
    /// 끄는 동안 손가락을 따라가는 애니메이션. 거의 바로 따라가도록 짧게 둔다.
    static let dragAnimation = Animation.interactiveSpring(response: 0.15, dampingFraction: 0.86, blendDuration: 0.25)
    /// 높이 단계를 옮기는 애니메이션이 눈에 띄게 끝나는 시간. 시트 안 내용의 아래 여백을 이 뒤에 늘린다.
    static let settleDuration: Duration = .milliseconds(600)
    /// 이보다 작게 바뀐 높이는 같은 높이로 본다.
    /// 부동소수점 계산 오차(끝자리 차이)만 거르는 값이다. 실제로 끌거나 멈춘 높이는 이보다 크게 바뀌므로 그대로 전달된다.
    static let heightChangeThreshold: CGFloat = 0.01

    /// 높이가 계산 오차보다 크게 바뀌었는지.
    static func isMeaningfulChange(from old: CGFloat, to new: CGFloat) -> Bool {
        abs(new - old) > heightChangeThreshold
    }
}

/// 시트에서 지금 화면에 올라와 보이는 위쪽 부분.
///
/// 시트는 가장 큰 높이로 그리고 아래로 내려 보일 높이만 올라오게 하므로, 이 모양으로 잘라 화면 밖으로 내린 부분은
/// 그리지도 터치를 받지도 않게 한다. 그리기는 `clipShape`, 터치는 `contentShape`로 자른다.
struct BottomSheetVisibleShape: Shape {
    var height: CGFloat
    /// 시트 위쪽 모서리 반지름. 모서리 바깥의 투명한 곳이 아래 화면의 터치를 가로채지 않게 같은 모양으로 둥글린다.
    var cornerRadius: CGFloat

    var animatableData: CGFloat {
        get { height }
        set { height = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let visible = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: min(max(height, 0), rect.height))
        return UnevenRoundedRectangle(
            topLeadingRadius: cornerRadius,
            topTrailingRadius: cornerRadius,
            style: .continuous
        )
        .path(in: visible)
    }
}

/// 시트 안 내용의 아래 여백을 바꿔 달라는 요청. `task(id:)`의 키로 써서, 끌기가 시작되거나 끝날 때 다시 판단한다.
struct BottomSheetInsetRequest: Equatable {
    /// 멈춘 높이 단계에서 가려지는 시트 아래쪽 높이.
    let target: CGFloat
    /// 이 시트나 위에 겹친 시트를 끄는 중인지. 움직이는 동안에는 여백을 바꾸지 않는다.
    let isMoving: Bool
}
