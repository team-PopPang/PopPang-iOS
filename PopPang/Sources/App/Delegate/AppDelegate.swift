//
//  AppDelegate.swift
//  PopPang
//
//  Created by 김동현 on 9/24/25.
//

import UIKit
import KakaoSDKCommon
import KakaoSDKAuth

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// 앱 실행 완료된 후 초기 설정 진행
    /// - Parameters:
    ///   - application: 현재 실행 중인 앱 객체
    ///   - launchOptions: 앱 실행 시 전달된 설정 정보 딕셔너리(푸시 알림, URL Scheme등)
    /// - Returns: 앱 실행이 성공적으로 완료되었는지 나타내는 Bool값
    ///
    /// - Important: 이 메서드에서 Kakao SDK 초기화를 성공해야 카카오 로그인 및 API 가 정상 동작
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 1. KakaoSdk 설정
        KakaoSDK.initSDK(appKey: Constants.KakaoAPI.key)
        
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
        if (AuthApi.isKakaoTalkLoginUrl(url)) {
            return AuthController.handleOpenUrl(url: url)
        }

        return false
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
