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
}
