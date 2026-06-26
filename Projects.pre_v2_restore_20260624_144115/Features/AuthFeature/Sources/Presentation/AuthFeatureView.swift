import Coordinator
import Domain
import SwiftUI

public struct AuthFeatureView: View {
    @Environment(RootCoordinator.self) private var coordinator

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AuthFeature")
                .font(.title.bold())
            Text("로그인 화면은 코디네이터 재구성 전 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            Button("임시 로그인") {
                Task { @MainActor in
                    coordinator.completeAuthentication(user: .adminUser)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
