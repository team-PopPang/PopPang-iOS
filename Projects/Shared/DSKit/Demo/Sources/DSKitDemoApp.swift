import DSKit
import SwiftUI
import UIKit

@main
struct DSKitDemoApp: App {
    init() {
        // 앱(`AppSDKInitializer`)과 같은 시스템 탭바 appearance를 적용해 기존 모양과 비교한다.
        UITabBar.configureAppearance()
    }

    var body: some Scene {
        WindowGroup {
            TabBarDemoView()
        }
    }
}
