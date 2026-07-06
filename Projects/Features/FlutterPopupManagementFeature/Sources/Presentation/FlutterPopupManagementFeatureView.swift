import SwiftUI
import UIKit

public struct FlutterPopupManagementFeatureView: UIViewControllerRepresentable {
    public init() {}

    public func makeUIViewController(context: Context) -> UINavigationController {
        // 앱 시작시
        FlutterRuntime.shared.start()

        let flutterViewController = FlutterRuntime.shared.makeViewController()
        flutterViewController.title = "Flutter Popup Management"

        return UINavigationController(rootViewController: flutterViewController)
    }

    public func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}
