import DSKit
import SwiftUI

/// 온보딩 아래 주황 버튼. `MainOrangeButton`과 모서리·높이·글꼴이 달라 온보딩에서만 쓴다.
struct OnboardingNextButton: View {
    let title: String
    let showsArrow: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(Font(UIFont.scdream(.medium, size: 15)))

                if showsArrow {
                    DSKitResource.image("OnboardingV2Arrow")
                        .resizable()
                        .frame(width: 24, height: 24)
                }
            }
            .foregroundStyle(Color.subWhite)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.mainOrange)
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PressableButtonStyle())
    }
}
