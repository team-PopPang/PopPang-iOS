import Core
import Domain
import Foundation
import UIKit
import UserNotifications

final class PopPangAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppNotificationManager.shared.configureNotification()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        AppNotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        AppNotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
}

final class AppNotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = AppNotificationManager()

    private var sessionStorage: AppSessionStorage
    private var userUsecase: UserUsecaseProtocol?

    override convenience init() {
        self.init(sessionStorage: AppSessionStorage(store: UserDefaultsStore()))
    }

    init(
        sessionStorage: AppSessionStorage,
        userUsecase: UserUsecaseProtocol? = nil
    ) {
        self.sessionStorage = sessionStorage
        self.userUsecase = userUsecase
        super.init()
    }

    func configure(
        sessionStorage: AppSessionStorage,
        userUsecase: UserUsecaseProtocol
    ) {
        self.sessionStorage = sessionStorage
        self.userUsecase = userUsecase
    }

    func configureNotification(
        notificationCenter: UNUserNotificationCenter = .current(),
        application: UIApplication = .shared
    ) {
        notificationCenter.delegate = self
        FirebaseMessagingBridge.setDelegate(self)

        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                print("❌ configureNotification 에러: \(error)")
                return
            }

            guard granted else { return }

            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    @objc(messaging:didReceiveRegistrationToken:)
    func messaging(_ messaging: Any, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken, fcmToken.isEmpty == false else {
            print("⚠️ FCM 토큰이 nil입니다.")
            return
        }

        sessionStorage.saveFCMToken(fcmToken)
        print("Firebase에서 APNs 토큰을 기반으로 FCM 등록 및 클라이언트로 토큰 발급")

        let snapshot = sessionStorage.loadSnapshot()
        guard let userID = snapshot.userID else { return }
        syncStoredToken(userUuid: userID)
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        FirebaseMessagingBridge.setAPNSToken(deviceToken)
        print("Apple의 APNs(푸시 서버) 디바이스 토큰을 Firebase에 전달 완료")
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ APNs 등록 실패:", error.localizedDescription)
    }

    func syncStoredToken(userUuid: String) {
        let snapshot = sessionStorage.loadSnapshot()
        guard let fcmToken = snapshot.fcmToken, fcmToken.isEmpty == false else { return }
        guard let userUsecase else { return }

        Task {
            do {
                let isSameToken = try await userUsecase.checkFcmToken(
                    userUuid: userUuid,
                    fcmToken: fcmToken
                )

                guard isSameToken == false else { return }

                try await userUsecase.updateFcmToken(
                    userUuid: userUuid,
                    fcmToken: fcmToken
                )
                print("로컬 FCM 토큰을 서버로 전송 및 갱신 완료")
            } catch {
                print("❌ FCM 토큰 중복 확인 실패: \(error)")
            }
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}

private enum FirebaseMessagingBridge {
    static func setDelegate(_ delegate: AnyObject) {
        guard let messaging = messagingInstance() else { return }
        _ = messaging.perform(NSSelectorFromString("setDelegate:"), with: delegate)
    }

    static func setAPNSToken(_ deviceToken: Data) {
        guard let messaging = messagingInstance() else { return }
        _ = messaging.perform(NSSelectorFromString("setAPNSToken:"), with: deviceToken)
    }

    private static func messagingInstance() -> AnyObject? {
        guard let messagingClass = NSClassFromString("FIRMessaging") else {
            return nil
        }

        return (messagingClass as AnyObject)
            .perform(NSSelectorFromString("messaging"))?
            .takeUnretainedValue()
    }
}
