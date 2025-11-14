//
//  AlertManager.swift
//  PopPang
//
//  Created by 김동현 on 11/1/25.
//

import UIKit

final class AlertManager {
    static let shared = AlertManager()
    private init() {}
    
    // 알림 권한
    func showPermissionAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(title: "알림 허용",
                                       message: "키쿼드 알림을 받으려면 알림 권한을 허용해 주세요.",
                                       preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "다음에 하기", style: .default))
        rootVC.present(alert, animated: true)
    }
    
    // 회원 탈퇴
    func showHardDeleteUserAlert(confirmHandler: @escaping () -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(title: "회원 탈퇴",
                                      message: "탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.",
                                      preferredStyle: .alert)
        
        let confirmAction = UIAlertAction(title: "탈퇴하기", style: .destructive) { _ in
             confirmHandler() // ✅ 외부에서 탈퇴 로직 실행
         }

         let cancelAction = UIAlertAction(title: "취소", style: .cancel)
        
        
        alert.addAction(confirmAction)
        alert.addAction(cancelAction)
        rootVC.present(alert, animated: true)
    }
    
    // 위치 권한
    func showLocationPermissionAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(title: "위치 권한이 필요합니다",
                                      message: "내 위치로 이동하려면 위치 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        rootVC.present(alert, animated: true)
    }
    
    func showKeywordLimitAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(title: "키워드 개수 제한",
                                      message: "키워드는 최대 5개 까지만 등록 가능합니다.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        rootVC.present(alert, animated: true)
    }
}
