import SwiftUI

/// 시트를 붙인 뷰 위에 하단 시트를 그리고, 손잡이로 높이를 바꾼다.
struct BottomSheetContainer<Content: View>: View {
    @Binding var detent: BottomSheetDetent?
    let detents: Set<BottomSheetDetent>
    /// 가장 낮은 단계보다 아래로 끌어 숨길 수 있는지.
    let canHide: Bool
    let content: Content

    @Environment(\.bottomSheetTopInset) private var topInset
    @Environment(\.bottomSheetBackground) private var background
    @Environment(\.bottomSheetCornerRadius) private var cornerRadius
    /// 손잡이를 끄는 동안 움직인 거리.
    /// 끄는 동안에는 시트 안에서만 높이를 바꾸고, 손을 뗄 때 한 번만 `detent`를 바꾼다.
    /// 끌기가 취소돼도(알림 센터를 내리거나 앱이 백그라운드로 갈 때) 0으로 돌아가도록 `@GestureState`로 둔다.
    @GestureState(resetTransaction: Transaction(animation: BottomSheetMetrics.animation))
    private var dragTranslation: CGFloat = 0
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
            // 키보드가 올라와도 시트를 밀어 올리지 않는다.
            .ignoresSafeArea(.keyboard)
            // 높이 단계가 바뀔 때만 애니메이션을 건다. 화면이 다시 그려진다고 시트 전체에 애니메이션을 걸지 않는다.
            .animation(BottomSheetMetrics.animation, value: detent)
    }

    private func sheet(detent: BottomSheetDetent, layout: BottomSheetLayout) -> some View {
        let sortedDetents = layout.sortedDetents(detents)
        let baseHeight = layout.height(for: detent)
        let height = min(
            max(baseHeight - dragTranslation, BottomSheetMetrics.grabberAreaHeight),
            layout.maxHeight
        )
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: cornerRadius,
            topTrailingRadius: cornerRadius,
            style: .continuous
        )

        return VStack(spacing: 0) {
            BottomSheetGrabber(
                onTap: {
                    self.detent = layout.detentAfterTap(from: detent, in: sortedDetents)
                },
                onIncrement: {
                    self.detent = layout.detentAfterIncrement(from: detent, in: sortedDetents)
                },
                onDecrement: {
                    self.detent = layout.detentAfterDecrement(
                        from: detent,
                        in: sortedDetents,
                        canHide: canHide
                    )
                }
            )
            .gesture(dragGesture(baseHeight: baseHeight, layout: layout, sortedDetents: sortedDetents))

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        // 가로 길이는 따로 계산하지 않고 시트를 붙인 뷰의 너비를 그대로 쓴다.
        .frame(maxWidth: .infinity)
        .frame(height: height, alignment: .top)
        .clipShape(shape)
        .background {
            // 내용은 safe area 안에 두고, 배경만 탭바와 홈 인디케이터 아래 화면 끝까지 깐다.
            shape
                .fill(background)
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private func dragGesture(
        baseHeight: CGFloat,
        layout: BottomSheetLayout,
        sortedDetents: [BottomSheetDetent]
    ) -> some Gesture {
        DragGesture(coordinateSpace: .global)
            .updating($dragTranslation) { value, translation, _ in
                translation = value.translation.height
            }
            .onEnded { value in
                let target = layout.targetDetent(
                    projectedHeight: baseHeight - value.predictedEndTranslation.height,
                    in: sortedDetents,
                    canHide: canHide
                )
                // 끈 거리는 `@GestureState`가 같은 애니메이션으로 0으로 되돌린다.
                withAnimation(BottomSheetMetrics.animation) {
                    detent = target
                }
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
