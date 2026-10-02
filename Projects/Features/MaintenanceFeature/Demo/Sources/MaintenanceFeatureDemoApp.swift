import MaintenanceFeature
import SwiftUI

@main
struct MaintenanceFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            MaintenanceDemoView()
        }
    }
}

/// 좌우로 넘겨 점검 화면의 상태별 모습을 비교한다
private struct MaintenanceDemoView: View {
    var body: some View {
        TabView {
            MaintenanceFeatureView()

            // 데모에서는 다시 시도 동작이 없다
            MaintenanceFeatureView(onRetry: {})

            MaintenanceFeatureView(reason: .offline, onRetry: {})

            MaintenanceFeatureView(isRetrying: true, onRetry: {})
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .indexViewStyle(.page(backgroundDisplayMode: .always))
        .ignoresSafeArea()
    }
}
