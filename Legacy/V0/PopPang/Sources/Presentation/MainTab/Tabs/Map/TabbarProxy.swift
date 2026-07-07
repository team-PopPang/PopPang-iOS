//
//  TabbarProxy.swift
//  PopPang
//
//  Created by 김동현 on 11/7/25.
//

import SwiftUI
import UIKit

struct TabBarProxy: UIViewControllerRepresentable {
    var callback: (_ view: UIView, _ tabBar: UITabBar) -> Void
    
    class ProxyController: UIViewController {
        var callback: (_ view: UIView, _ tabBar: UITabBar) -> Void = { _, _ in }
        
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if let tabBarController = self.tabBarController {
                callback(tabBarController.view, tabBarController.tabBar)
            }
        }
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = ProxyController()
        vc.callback = callback
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
