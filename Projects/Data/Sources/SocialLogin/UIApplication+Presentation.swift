import UIKit

extension UIApplication {
    /// 화면에 떠 있는 scene의 key window. 활성 scene을 먼저 찾는다.
    var activeKeyWindow: UIWindow? {
        let windowScenes = connectedScenes.compactMap { $0 as? UIWindowScene }
        let activeScenes = windowScenes.filter { $0.activationState == .foregroundActive }
        return (activeScenes + windowScenes)
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    /// 소셜 로그인 화면을 띄울 가장 위의 화면
    var topViewController: UIViewController? {
        var top = activeKeyWindow?.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}
