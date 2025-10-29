//
//  AppDelegate.swift
//  PopPang
//
//  Created by 김동현 on 9/24/25.
//

import UIKit
import KakaoSDKCommon
import KakaoSDKAuth
import GoogleSignIn
import NMapsMap
import FirebaseCore
import FirebaseMessaging

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// 앱 실행 완료된 후 초기 설정 진행
    /// - Parameters:
    ///   - application: 현재 실행 중인 앱 객체
    ///   - launchOptions: 앱 실행 시 전달된 설정 정보 딕셔너리(푸시 알림, URL Scheme등)
    /// - Returns: 앱 실행이 성공적으로 완료되었는지 나타내는 Bool값
    ///
    /// - Important: 이 메서드에서 Kakao SDK 초기화를 성공해야 카카오 로그인 및 API 가 정상 동작
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        

        // 0. firebase 초기화
        FirebaseApp.configure()
        
        // 1. 알림 권한 요청
        NotificationManager.shared.configureNotification()
        
        // 2. KakaoSDK 설정
        KakaoSDK.initSDK(appKey: Constants.KakaoAPI.key)
        
        // 3-1. NaverMapSDK 설정
        NMFAuthManager.shared().ncpKeyId = Constants.NaverAPI.key
        
        // 3-2. 지도 오토 레이아웃 경고 제거
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        return true
    }
    
    /// 앱이 외부 URL을 열 때 호출
    /// - Parameters:
    ///   - app: 현재 실행 중인 앱 객체
    ///   - url: 열리는 외부 리소스 URL (ex: 카카오톡 로그인 콜백)
    ///   - options: URL 열기 동작과 관련된 추가 옵션 정보
    /// - Returns: URL을 정상적으로 처리했는지 나타내는 Bool값
    ///
    /// - Note: 카카오톡 로그인 시 카카오톡 앱에서 인증 후 돌아오는 URL을 처리한다
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        // MARK: - Kakao
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.handleOpenUrl(url: url)
        }
        
        // MARK: - Google
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // MARK: - 카카오 공유로 앱 실행 시 딥링크 처리
        if url.scheme?.hasPrefix("kakao") == true && url.host == "kakaolink" {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let popupId = components.queryItems?.first(where: { $0.name == "popupId" })?.value {
                print("딥링크로 받은 popupId: \(popupId)")
                
                NotificationCenter.default.post(name: .didReceiveDeepLink,
                                                object: nil,
                                                userInfo: ["popupId": popupId])
            }
        }
        
        return true
    }
    
    
    /// 새로운 씬(Session)을 생성할 때 호출
    ///
    /// - Parameters:
    ///   - application: 현재 실행 중인 앱 객체
    ///   - connectingSceneSession: 새로 생성되는 씬 세션
    ///   - options: 씬 연결과 관련된 추가 옵션
    /// - Returns: 생성된 씬의 설정을 담은 `UISceneConfiguration` 객체
    ///
    /// - Note: 여러 씬(멀티 윈도우)을 지원하는 환경에서 각 씬을 어떤 Delegate와 연결할지 결정
    ///   여기서는 `SceneDelegate`를 연결하여 카카오 로그인 URL 처리 등을 위임
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        
        let sceneConfiguration = UISceneConfiguration(name: nil,
                                                      sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self
        return sceneConfiguration
    }
}

// 딥링크 노티 이름
extension Notification.Name {
    static let didReceiveDeepLink = Notification.Name("didReceiveDeepLink")
}


// MARK: - 알림 관련(Swizzling)
extension AppDelegate {

    // APNs 등록 성공 → APNs 토큰을 FCM에 연결
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NotificationManager.shared.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    // APNs 등록 실패 로깅
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NotificationManager.shared.didFailToRegisterForRemoteNotifications(error: error)
    }
}

final class NotificationManager: NSObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = NotificationManager()
    private override init() {}
    
    /// 알림 권한 요청 및 APNs 등록
    func configureNotification() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        Messaging.messaging().delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            // 요청 과정에서 오류가 발생하였는지 확인
            if let error = error {
                print("❌ configureNotification 에러: \(error)")
                return
            }
            
            // 알림 권한 요청 결과
            DispatchQueue.main.async {
                if granted {
                    // 권한이 허용된 경우
                    UIApplication.shared.registerForRemoteNotifications()
                }
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
        
        guard let fcmToken = fcmToken else {
            print("⚠️ FCM 토큰이 nil입니다.")
            return
        }
        print("📱 FCM 토큰 수신 완료: \(fcmToken)")
        UserDefaultsManager.saveFcmToken(fcmToken)
        
        // 🔹 (선택) Firestore나 서버에 토큰 저장
        // FcmTokenManager.shared.saveToken(fcmToken)
    }
    
    // APNs 등록 성공 → APNs 토큰을 FCM에 연결
    func didRegisterForRemoteNotifications(deviceToken: Data) {
        // 1) APNs 토큰 등록
        Messaging.messaging().apnsToken = deviceToken
        print("📮 APNs token set (\(deviceToken.count) bytes)")

        // APNs 토큰이 설정된 '이후'에 FCM 토큰을 요청 (선택)
        Messaging.messaging().token { token, error in
            if let token = token?.trimmingCharacters(in: .whitespacesAndNewlines) {
                print("✅ Fresh FCM token:", token, "len:", token.count)
            } else if let error = error {
                print("❌ FCM 토큰 가져오기 실패:", error.localizedDescription)
            }
        }
    }

    // APNs 등록 실패 로깅
    func didFailToRegisterForRemoteNotifications(error: Error) {
        print("❌ APNs 등록 실패:", error.localizedDescription)
    }
    
    // 🔔 포그라운드 상태에서 알림이 도착했을 때 호출됨
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // ✅ 알림을 배너 + 사운드 + 리스트에 표시되게 함
        completionHandler([.banner, .sound, .list])
    }
}
