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

    private var pushTokenStorage: PushTokenStorage
    /// 로그인 여부를 판단한다. V2 요청은 로그인 토큰으로 가므로 저장된 사용자 ID가 아니라 토큰이 있는지로 본다.
    private var authTokenStorage: AuthTokenStorage
    private var userUsecase: UserUsecaseProtocol?
    /// 마지막으로 시작한 토큰 저장 요청. 다음 요청은 이 요청이 끝난 뒤에 보내 순서를 지킨다.
    private var syncTask: Task<Void, Never>?
    /// 로그인 복구가 끝나 메인 화면에 들어간 상태인지. 앱이 켜지는 중(로그인 확인 중)이나 로그아웃 뒤에는 보내지 않는다.
    private var isSessionActive = false
    private let syncLock = NSLock()

    override convenience init() {
        let store = UserDefaultsStore()
        self.init(
            pushTokenStorage: PushTokenStorage(store: store),
            authTokenStorage: AuthTokenStorage(store: store)
        )
    }

    init(
        pushTokenStorage: PushTokenStorage,
        authTokenStorage: AuthTokenStorage,
        userUsecase: UserUsecaseProtocol? = nil
    ) {
        self.pushTokenStorage = pushTokenStorage
        self.authTokenStorage = authTokenStorage
        self.userUsecase = userUsecase
        super.init()
    }

    func configure(
        pushTokenStorage: PushTokenStorage,
        authTokenStorage: AuthTokenStorage,
        userUsecase: UserUsecaseProtocol
    ) {
        self.pushTokenStorage = pushTokenStorage
        self.authTokenStorage = authTokenStorage
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
    /// 서버는 받은 값을 저장만 하므로 V1처럼 중복 확인을 먼저 하지 않는다(V2에는 확인 API가 없다).
    /// 같은 토큰을 다시 보내도 결과가 같아 따로 막지 않는다. 막으면 같은 실행에서 다른 계정으로 로그인했을 때 그 계정의 토큰이 가지 않는다.
    ///
    /// 요청은 하나씩 순서대로 보내고, 보낼 때 저장된 최신 토큰을 읽는다.
    /// 앱 시작 직후 Firebase가 토큰을 바꿔 두 번 보내도 마지막에 도착하는 값이 최신 토큰이 된다.
    /// 로그인 복구나 로그인이 끝나 메인 화면에 들어갈 때 AppFeature가 부른다. 이때부터 토큰을 서버에 보낸다.
    func startSession() {
        syncLock.lock()
        isSessionActive = true
        syncLock.unlock()
        syncStoredToken()
    }

    /// 로그아웃·세션 만료 때 AppFeature가 부른다. 기다리던 전송을 취소하고 다시 로그인할 때까지 보내지 않는다.
    func endSession() {
        syncLock.lock()
        isSessionActive = false
        syncTask?.cancel()
        syncTask = nil
        syncLock.unlock()
    }

    private func syncStoredToken() {
        syncLock.lock()
        defer { syncLock.unlock() }
        // 앱이 켜지는 중에는 보내지 않는다. 로그인 확인 중에 이 요청이 401을 받으면 실행 판단 전에 로그아웃될 수 있다.
        guard isSessionActive, let userUsecase else { return }

        let previous = syncTask
        syncTask = Task { [weak self] in
            await previous?.value
            guard let self, Task.isCancelled == false else { return }
            // 로그인 토큰이 없으면 서버가 거절하므로 보내지 않는다. 로그인을 마치면 AppFeature가 다시 부른다.
            guard self.authTokenStorage.loadTokens() != nil else { return }
            guard let fcmToken = self.pushTokenStorage.load(), fcmToken.isEmpty == false else { return }
            do {
                try await userUsecase.updateFcmToken(fcmToken: fcmToken)
                Logger.d("FCM 토큰을 서버에 저장 완료")
            } catch {
                // 실패하면 다음 기회(앱 시작·로그인·토큰 갱신)에 다시 보낸다.
                Logger.e("❌ FCM 토큰 저장 실패: \(error)")
            }
        }
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

        // 메인 화면에 들어간 상태면 바로 보내고, 아니면 저장만 해 두었다가 startSession에서 보낸다.
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
