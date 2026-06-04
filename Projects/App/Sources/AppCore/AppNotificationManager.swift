import Core
import Domain
import FirebaseMessaging
import Foundation
import UIKit
import UserNotifications

final class PopPangAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppSDKInitializer.configure()
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

final class AppNotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
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
        Messaging.messaging().delegate = self

        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
                Logger.e("❌ configureNotification 에러: \(error)")
                return
            }

            guard granted else { return }

            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Logger.d("Firebase에서 APNs 토큰을 기반으로 FCM 등록 및 클라이언트로 토큰 발급")
        handleFCMToken(fcmToken, source: "MessagingDelegate")
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Logger.d("Apple의 APNs(푸시 서버) 디바이스 토큰을 Firebase에 전달 완료")
        #if DEBUG
        Logger.d("APNs 디버그 디바이스 토큰: \(deviceToken.hexString)")
        #endif
        requestCurrentFCMToken(reason: "APNs 토큰 등록 직후")
    }

    func didFailToRegisterForRemoteNotifications(error: Error) {
        Logger.e("❌ APNs 등록 실패: \(error.localizedDescription)")
    }

    func syncStoredToken(userUuid: String) {
        let snapshot = sessionStorage.loadSnapshot()
        guard let fcmToken = snapshot.fcmToken, fcmToken.isEmpty == false else { return }
        guard let userUsecase else { return }

        Task {
            do {
                Logger.d("로그인된 uuid가 있어 FCM 토큰 서버 일치 여부 확인")
                let isSameToken = try await userUsecase.checkFcmToken(
                    userUuid: userUuid,
                    fcmToken: fcmToken
                )

                guard isSameToken == false else { return }

                try await userUsecase.updateFcmToken(
                    userUuid: userUuid,
                    fcmToken: fcmToken
                )
                Logger.d("로컬 FCM 토큰을 서버로 전송 및 갱신 완료")
            } catch {
                Logger.e("❌ FCM 토큰 중복 확인 실패: \(error)")
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

    private func requestCurrentFCMToken(reason: String) {
        Messaging.messaging().token { [weak self] fcmToken, error in
            if let error {
                Logger.e("❌ FCM 토큰 요청 실패(\(reason)): \(error.localizedDescription)")
                return
            }

            self?.handleFCMToken(fcmToken, source: reason)
        }
    }

    private func handleFCMToken(_ fcmToken: String?, source: String) {
        guard let fcmToken, fcmToken.isEmpty == false else {
            Logger.w("⚠️ FCM 토큰이 nil 또는 빈 값입니다. source=\(source)")
            return
        }

        sessionStorage.saveFCMToken(fcmToken)
        Logger.d("FCM 토큰 저장 완료 source=\(source)")

        let snapshot = sessionStorage.loadSnapshot()
        guard let userID = snapshot.userID else {
            Logger.w("⚠️ uuid 없음")
            return
        }
        syncStoredToken(userUuid: userID)
    }
}

#if DEBUG
private extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
