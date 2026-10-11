import SwiftUI

/// 눌렀을 때 살짝 작아지고 흐려지는 효과. `PPButtonStyle`도 같은 효과를 쓴다.
public struct PressableButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .ppPressFeedback(isPressed: configuration.isPressed)
    }
}

extension View {
    /// 버튼 스타일들이 같은 눌림 효과를 쓰도록 값을 한 곳에 둔다.
    func ppPressFeedback(isPressed: Bool) -> some View {
        scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.85 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
}
