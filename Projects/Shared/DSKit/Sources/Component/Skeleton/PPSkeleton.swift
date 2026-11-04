import SwiftUI

/// 불러오는 동안 내용 자리에 두는 회색 블록.
///
/// 실제 화면 배치를 따라 블록을 놓고, 묶음 전체에 `ppSkeletonShimmer()`를 한 번 입힌다.
/// `width`가 `nil`이면 남은 폭을 모두 쓴다.
public struct PPSkeletonBlock: View {
    private let width: CGFloat?
    private let height: CGFloat
    private let radius: CGFloat

    public init(width: CGFloat? = nil, height: CGFloat, radius: CGFloat = PPRadius.small) {
        self.width = width
        self.height = height
        self.radius = radius
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: radius)
            .fill(PPColor.divider)
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

public extension View {
    /// 스켈레톤 묶음 위로 밝은 빛이 왼쪽에서 오른쪽으로 지나가게 한다.
    ///
    /// 블록마다 따로 입히지 않고 묶음에 한 번 입혀서 모든 블록이 같은 박자로 빛난다.
    /// "동작 줄이기"를 켠 기기에서는 움직이지 않고 회색 블록만 보인다.
    func ppSkeletonShimmer() -> some View {
        modifier(PPSkeletonShimmerModifier())
    }
}

private struct PPSkeletonShimmerModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = 0

    /// 빛 띠의 폭 (묶음 폭에 대한 비율)
    private let bandRatio: CGFloat = 0.6

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    GeometryReader { proxy in
                        let width = proxy.size.width
                        LinearGradient(
                            colors: [.clear, PPColor.background.opacity(0.7), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: width * bandRatio)
                        // 띠가 왼쪽 밖에서 시작해 오른쪽 밖까지 지나간다.
                        .offset(x: -width * bandRatio + phase * width * (1 + bandRatio))
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
            .onAppear { startShimmer() }
            // 화면을 벗어났다 돌아오면 phase가 이미 1이라 애니메이션이 다시 걸리지 않는다. 처음 값으로 돌려 둔다.
            .onDisappear { phase = 0 }
            .onChange(of: reduceMotion) { _, _ in
                phase = 0
                startShimmer()
            }
    }

    private func startShimmer() {
        guard !reduceMotion else { return }
        // 처음 값(0)에서 다음 프레임에 시작해야 반복 애니메이션이 새로 걸린다.
        DispatchQueue.main.async {
            withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                phase = 1
            }
        }
    }
}
