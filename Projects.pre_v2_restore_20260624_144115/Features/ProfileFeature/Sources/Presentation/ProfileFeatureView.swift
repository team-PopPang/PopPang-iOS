import ProfileFeatureInterface
import SwiftUI

public struct ProfileFeatureView: View {
    private let userUuid: String
    private let nickname: String
    private let isAlerted: Bool
    private let router: any ProfileFeatureRouting

    public init(
        userUuid: String = "demo-user",
        nickname: String = "홍길동",
        isAlerted: Bool = false,
        router: any ProfileFeatureRouting
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.isAlerted = isAlerted
        self.router = router
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ProfileFeature")
                .font(.title.bold())
            Text("\(nickname)님의 프로필 화면은 임시 placeholder 상태입니다.")
                .foregroundStyle(.secondary)
            Text("알림 수신: \(isAlerted ? "ON" : "OFF")")
                .font(.subheadline)
            Button("알림 팝업 열기") {
                router.route(to: .alert)
            }
            .buttonStyle(.bordered)
            Button("프로필 설정 열기") {
                router.route(to: .profileSetting(nickname: nickname, isAlerted: isAlerted))
            }
            .buttonStyle(.borderedProminent)
            Button("공지사항 열기") {
                router.route(to: .notifications)
            }
            .buttonStyle(.bordered)
            Button("서비스 약관 열기") {
                router.route(to: .serviceTerms)
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

public struct ProfileSettingFeatureView: View {
    private let userUuid: String
    private let nickname: String
    private let isAlerted: Bool
    private let router: any ProfileFeatureRouting

    public init(
        userUuid: String,
        nickname: String,
        isAlerted: Bool,
        router: any ProfileFeatureRouting
    ) {
        self.userUuid = userUuid
        self.nickname = nickname
        self.isAlerted = isAlerted
        self.router = router
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ProfileSettingFeature")
                .font(.title.bold())
            Text("userUuid: \(userUuid)")
                .font(.subheadline)
            Text("닉네임: \(nickname), 알림: \(isAlerted ? "ON" : "OFF")")
                .foregroundStyle(.secondary)
            Button("닉네임 임시 변경") {
                router.route(to: .updateNickname("\(nickname)-temp"))
            }
            .buttonStyle(.bordered)
            Button("로그아웃") {
                router.route(to: .logout)
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

public struct NotificationFeatureView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NotificationFeature")
                .font(.title.bold())
            Text("공지사항 화면 placeholder")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}

public struct ServiceTermsFeatureView: View {
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ServiceTermsFeature")
                .font(.title.bold())
            Text("서비스 약관 화면 placeholder")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(24)
    }
}
