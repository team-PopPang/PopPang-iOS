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

    /// 빛 띠의 폭 (묶음 폭에 대한 비율)
    private let bandRatio: CGFloat = 0.6
    /// 빛이 한 번 지나가는 시간(초)
    private let cycle: Double = 1.3

    func body(content: Content) -> some View {
        content
            .overlay {
                if !reduceMotion {
                    // 시계로 빛 위치를 계산한다. 화면에 보일 때만 갱신되고, 다시 나타나면 이어서 돈다.
                    // 따로 시작·정지하는 상태가 없어 화면 전환이나 설정 변경과 경쟁하지 않는다.
                    TimelineView(.animation) { timeline in
                        let progress = timeline.date.timeIntervalSinceReferenceDate
                            .truncatingRemainder(dividingBy: cycle) / cycle
                        GeometryReader { proxy in
                            let width = proxy.size.width
                            LinearGradient(
                                colors: [.clear, PPColor.background.opacity(0.7), .clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: width * bandRatio)
                            // 띠가 왼쪽 밖에서 시작해 오른쪽 밖까지 지나간다.
                            .offset(x: -width * bandRatio + CGFloat(progress) * width * (1 + bandRatio))
                        }
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
            }
    }
}
