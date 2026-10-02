import DSKit
import SwiftUI

/// 앱 시작 시 서버 헬스 체크에 실패했을 때 보여 주는 화면
public struct MaintenanceFeatureView: View {
    private let reason: MaintenanceReason
    private let isRetrying: Bool
    private let onRetry: (() -> Void)?

    /// - Parameters:
    ///   - reason: 화면을 띄운 이유. 이유에 따라 문구가 바뀐다.
    ///   - isRetrying: 다시 확인하는 중인지 여부. `true`면 버튼을 비활성화한다.
    ///   - onRetry: 다시 시도 버튼을 눌렀을 때 실행할 동작. `nil`이면 버튼을 숨긴다.
    public init(
        reason: MaintenanceReason = .serverUnavailable,
        isRetrying: Bool = false,
        onRetry: (() -> Void)? = nil
    ) {
        self.reason = reason
        self.isRetrying = isRetrying
        self.onRetry = onRetry
    }

    public var body: some View {
        ZStack {
            Color.categoryOrange
                .ignoresSafeArea()

            VStack(spacing: 0) {
                DSKitResource.image("maintenanceIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 168, height: 168)
                    .accessibilityHidden(true)

                noticeBadge
                    .padding(.top, 24)

                Text(reason.title)
                    .font(.scdream(.extraBold, size: 26))
                    .kerning(-0.3)
                    .foregroundStyle(Color.maintenanceTitle)
                    .padding(.top, 14)

                Text(reason.message)
                    .font(.scdream(.regular, size: 15))
                    .foregroundStyle(Color.mainGray9)
                    .padding(.top, 10)

                retryNotice
                    .padding(.top, 28)

                if let onRetry {
                    MainOrangeButton(
                        buttonTitle: isRetrying ? "확인 중..." : "다시 시도",
                        action: onRetry
                    )
                    .disabled(isRetrying)
                    .opacity(isRetrying ? 0.6 : 1)
                    .padding(.top, 24)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 28)
        }
    }
}

private extension MaintenanceFeatureView {
    var noticeBadge: some View {
        Text(reason.badge)
            .font(.scdream(.bold, size: 13))
            .foregroundStyle(Color.maintenanceAccent)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color.subWhite, in: Capsule())
    }

    var retryNotice: some View {
        HStack(spacing: 6) {
            Image(systemName: reason.noticeIconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.maintenanceAccent)
                .accessibilityHidden(true)

            Text(reason.notice)
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .padding(.horizontal, 20)
        .background(Color.subWhite, in: RoundedRectangle(cornerRadius: 14))
    }
}

private extension MaintenanceReason {
    var badge: String {
        switch self {
        case .serverUnavailable:
            "서비스 점검 안내"
        case .offline:
            "네트워크 안내"
        }
    }

    var title: String {
        switch self {
        case .serverUnavailable:
            "잠시 점검 중이에요"
        case .offline:
            "인터넷 연결을 확인해 주세요"
        }
    }

    var message: String {
        switch self {
        case .serverUnavailable:
            "더 나은 팝팡을 위해 개선하고 있어요."
        case .offline:
            "와이파이나 모바일 데이터가 켜져 있는지 확인해 주세요."
        }
    }

    var notice: String {
        switch self {
        case .serverUnavailable:
            "잠시 후 다시 이용해 주세요."
        case .offline:
            "연결된 뒤 다시 시도해 주세요."
        }
    }

    var noticeIconName: String {
        switch self {
        case .serverUnavailable:
            "clock"
        case .offline:
            "wifi.slash"
        }
    }
}

private extension Color {
    /// 배지와 아이콘 색. 흰 배경 위 작은 글씨의 대비를 위해 `mainOrange`보다 어둡다.
    static let maintenanceAccent = Color(hex: "#B84A00")

    static let maintenanceTitle = Color(hex: "#222222")
}

#Preview("서버 이상 · 버튼 없음") {
    MaintenanceFeatureView()
}

#Preview("서버 이상 · 다시 시도") {
    MaintenanceFeatureView(onRetry: {})
}

#Preview("오프라인 · 다시 시도") {
    MaintenanceFeatureView(reason: .offline, onRetry: {})
}

#Preview("확인 중") {
    MaintenanceFeatureView(isRetrying: true, onRetry: {})
}
