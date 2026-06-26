import Coordinator
import Domain
import SwiftUI

public struct RegisterFlowFeatureView: View {
    @Environment(RootCoordinator.self) private var coordinator

    private let user: User?

    public init(user: User?) {
        self.user = user
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("RegisterFlowFeature")
                .font(.title.bold())
            Text("회원가입 단계는 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            if let nickname = user?.nickname {
                Text("전달된 사용자: \(nickname)")
                    .font(.subheadline)
            }
            Button("임시 가입 완료") {
                Task { @MainActor in
                    coordinator.pendingRegistrationUser = nil
                    coordinator.completeAuthentication(user: user ?? .adminUser)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
