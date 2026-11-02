import ComposableArchitecture
import UIKit
import UserNotifications

/// 가입 완료 화면의 "알림 켜고 시작하기"에서 알림 권한을 묻는다.
///
/// 실제 구현 `live`는 `AppBootstrap`이 주입한다. 주입 전 기본값(`liveValue`)은 다른 client처럼 `unimplemented`다.
public struct NotificationPermissionClient: Sendable {
    /// 알림 권한을 요청한다. 이미 정했으면 팝업 없이 지금 상태를 돌려준다.
    /// - Returns: 허용했으면 `true`
    public var request: @Sendable () async -> Bool

    public init(request: @escaping @Sendable () async -> Bool) {
        self.request = request
    }
}

extension NotificationPermissionClient {
    /// 시스템 알림 권한을 요청한다. usecase 없이 `UNUserNotificationCenter`만 쓴다.
    public static let live = Self(request: {
        let granted = (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted {
            // 앱 시작 때 권한이 없었으면 APNs 등록을 하지 않았으므로 여기서 등록해 푸시 토큰을 받게 한다.
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
        return granted
    })

    /// 주입하지 않고 부르면 이슈로 알리고 거부로 처리한다. 화면은 거부여도 메인으로 가므로 막히지 않는다.
    public static let unimplemented = Self(request: {
        reportIssue("NotificationPermissionClient.request is unimplemented")
        return false
    })
}

extension NotificationPermissionClient: DependencyKey {
    public static let liveValue = Self.unimplemented
}

extension NotificationPermissionClient: TestDependencyKey {
    public static let testValue = Self.unimplemented
}

extension DependencyValues {
    public var notificationPermissionClient: NotificationPermissionClient {
        get { self[NotificationPermissionClient.self] }
        set { self[NotificationPermissionClient.self] = newValue }
    }
}
