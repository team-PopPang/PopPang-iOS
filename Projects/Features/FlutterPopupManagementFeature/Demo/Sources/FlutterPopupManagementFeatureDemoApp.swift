import SwiftUI
import FlutterPopupManagementFeature

@main
struct FlutterPopupManagementFeatureDemoApp: App {
    init() {
        FlutterEngine.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            FlutterPopupManagementFeatureView()
        }
    }
}
