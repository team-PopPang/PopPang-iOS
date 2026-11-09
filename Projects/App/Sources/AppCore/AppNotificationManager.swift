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
        
        // 초기 설정
        AppSDKInitializer.configure()
        
        // FCM 설정
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

    private var sessionStorage: LocalSessionStorage
    private var pushTokenStorage: PushTokenStorage
    private var userUsecase: UserUsecaseProtocol?
    /// 이번 실행에서 서버에 보낸 토큰. 앱 시작 때 APNs 등록 직후와 로그인 직후에 같은 토큰을 두 번 보내지 않게 한다.
    private var lastSyncedFCMToken: String?

    override convenience init() {
        let store = UserDefaultsStore()
        self.init(
            sessionStorage: LocalSessionStorage(store: store),
            pushTokenStorage: PushTokenStorage(store: store)
        )
    }

    init(
        sessionStorage: LocalSessionStorage,
        pushTokenStorage: PushTokenStorage,
        userUsecase: UserUsecaseProtocol? = nil
    ) {
        self.sessionStorage = sessionStorage
        self.pushTokenStorage = pushTokenStorage
        self.userUsecase = userUsecase
        super.init()
    }

    func configure(
        sessionStorage: LocalSessionStorage,
        pushTokenStorage: PushTokenStorage,
        userUsecase: UserUsecaseProtocol
    ) {
        self.sessionStorage = sessionStorage
        self.pushTokenStorage = pushTokenStorage
        self.userUsecase = userUsecase
    }

    func configureNotification(
        notificationCenter: UNUserNotificationCenter = .current(),
        application: UIApplication = .shared
    ) {
        notificationCenter.delegate = self
        Messaging.messaging().delegate = self

        notificationCenter.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            // 요청 과정에서 오류가 발생하였는지 확인
            if let error {
                Logger.e("❌ configureNotification 에러: \(error)")
                return
            }

            guard granted else { return }
            
            DispatchQueue.main.async {
                // 권한이 허용된 경우
                application.registerForRemoteNotifications()
            }
        }
    }

    /// FCM 등록 토큰을 수신했을 때 호출되는 메서드입니다.
    ///
    /// - Parameter fcmToken: Firebase Cloud Messaging에서 발급받은 고유 토큰 문자열.
    ///
    /// - Note:
    ///   앱이 처음 실행되거나, APNs 토큰이 변경될 때, 또는 Firebase 토큰이 갱신될 때 자동으로 호출됩니다.
    ///   이 토큰은 Firestore에 저장하거나, 서버 API로 전달해 푸시 발송 대상 식별용으로 사용합니다.
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        Logger.d("Firebase에서 APNs 토큰을 기반으로 FCM 등록 및 클라이언트로 토큰 발급")
        handleFCMToken(fcmToken, source: "MessagingDelegate")
    }

    // APNs 등록 성공 → APNs 토큰을 FCM에 연결
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
        Logger.d("Apple의 APNs(푸시 서버) 디바이스 토큰을 Firebase에 전달 완료")
        #if DEBUG
        Logger.d("APNs 디버그 디바이스 토큰: \(deviceToken.hexString)")
        #endif
        requestCurrentFCMToken(reason: "APNs 토큰 등록 직후")
    }

    // APNs 등록 실패 로깅
    func didFailToRegisterForRemoteNotifications(error: Error) {
        Logger.e("❌ APNs 등록 실패: \(error.localizedDescription)")
    }

    /// 로그인한 사용자의 푸시 토큰을 서버에 저장한다(V2 `PUT /api/v2/user/fcm-token`).
    /// 서버는 저장만 하므로 V1처럼 중복 확인을 먼저 하지 않는다. 같은 실행에서 같은 토큰을 이미 보냈으면 다시 보내지 않는다.
    func syncStoredToken() {
        // Firebase 콜백(다른 스레드)과 AppFeature에서 불린다. 보낸 토큰 기록은 메인 스레드에서만 읽고 쓴다.
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.syncStoredToken() }
            return
        }
        guard let fcmToken = pushTokenStorage.load(), fcmToken.isEmpty == false else { return }
        guard let userUsecase else { return }
        guard fcmToken != lastSyncedFCMToken else { return }
        lastSyncedFCMToken = fcmToken

        Task {
            do {
                try await userUsecase.updateFcmToken(fcmToken: fcmToken)
                Logger.d("FCM 토큰을 서버에 저장 완료")
            } catch {
                // 실패하면 다음 기회(앱 시작·로그인·토큰 갱신)에 다시 보낸다.
                await MainActor.run { self.clearLastSyncedToken(ifEqualTo: fcmToken) }
                Logger.e("❌ FCM 토큰 저장 실패: \(error)")
            }
        }
    }

    private func clearLastSyncedToken(ifEqualTo fcmToken: String) {
        if lastSyncedFCMToken == fcmToken { lastSyncedFCMToken = nil }
    }

    // 🔔 포그라운드 상태에서 알림이 도착했을 때 호출됨
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // ✅ 알림을 배너 + 사운드 + 리스트에 표시되게 함
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

        pushTokenStorage.save(fcmToken)
        Logger.d("FCM 토큰 저장 완료 source=\(source)")

        // 로그인 전이면 저장만 하고, 로그인한 뒤 AppFeature가 보낸다.
        guard sessionStorage.loadSnapshot().userID != nil else {
            Logger.w("⚠️ 로그인 전이라 FCM 토큰을 서버에 보내지 않음")
            return
        }
        syncStoredToken()
    }
}

#if DEBUG
private extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
#endif
