import Coordinator
import SwiftUI

public struct OnboardingFeatureView: View {
    @Environment(RootCoordinator.self) private var coordinator

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("OnboardingFeature")
                .font(.title.bold())
            Text("온보딩 화면은 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            Button("건너뛰기") {
                coordinator.completeOnboarding()
            }
            .buttonStyle(.bordered)
            Button("온보딩 완료") {
                coordinator.completeOnboarding()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
