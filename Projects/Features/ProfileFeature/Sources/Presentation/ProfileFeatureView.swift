import SwiftUI

public struct ProfileFeatureView: View {
    @Environment(ProfileFeatureCoordinator.self) private var coordinator
    private let userID: String
    private let onLogout: () -> Void

    public init(
        userID: String = "demo-user",
        onLogout: @escaping () -> Void = {}
    ) {
        self.userID = userID
        self.onLogout = onLogout
    }

    public var body: some View {
        List {
            Section("계정") {
                profileRow(title: "사용자 ID", value: userID)
                profileRow(title: "알림 설정", value: "관심 키워드 기준")
                Button {
                    coordinator.push(.alert)
                } label: {
                    profileRow(title: "알림센터", value: "활동/키워드")
                }
            }

            Section("서비스") {
                Button {
                    coordinator.push(.profileSetting)
                } label: {
                    profileRow(title: "프로필 설정", value: "닉네임/계정")
                }

                Button {
                    coordinator.push(.notifications)
                } label: {
                    profileRow(title: "공지사항", value: "업데이트/안내")
                }

                Button {
                    coordinator.push(.serviceTerms)
                } label: {
                    profileRow(title: "서비스 이용약관", value: "정책 보기")
                }

                profileRow(title: "문의", value: "support@poppang.app")
                profileRow(title: "버전", value: "modular-preview")
            }

            Section {
                Button("로그아웃", role: .destructive, action: onLogout)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func profileRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
