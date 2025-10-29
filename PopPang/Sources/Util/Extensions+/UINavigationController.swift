//
//  UINavigationController.swift
//  PopPang
//
//  Created by 김동현 on 10/29/25.
//

// MARK: - 제스처 복원
import UIKit

extension UINavigationController: @retroactive ObservableObject, @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self // swipe로 뒤로 가기 활성화
    }

    open func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}
