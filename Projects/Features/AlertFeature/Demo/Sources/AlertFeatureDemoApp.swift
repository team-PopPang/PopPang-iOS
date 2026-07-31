import ComposableArchitecture
import Foundation
import SwiftUI

@main
struct AlertFeatureDemoApp: App {
    private let demoUserUuid = Bundle.main.object(
        forInfoDictionaryKey: "ALERT_DEMO_USER_UUID"
    ) as? String ?? ""

    var body: some Scene {
        WindowGroup {
            PopupPaginationDemoView(
                store: Store(
                    initialState: PopupPaginationDemoFeature.State(
                        userUuid: demoUserUuid
                    )
                ) {
                    PopupPaginationDemoFeature()
                }
            )
        }
    }
}
