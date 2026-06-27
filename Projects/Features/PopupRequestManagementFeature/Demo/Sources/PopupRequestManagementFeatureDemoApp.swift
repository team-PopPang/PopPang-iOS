import ComposableArchitecture
import PopupRequestManagementFeature
import SwiftUI

@main
struct PopupRequestManagementFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PopupRequestManagementFlowView(
                store: Store(initialState: PopupRequestManagementFlowFeature.State(adminUuid: "admin-user")) {
                    PopupRequestManagementFlowFeature()
                } withDependencies: {
                    $0.popupRequestManagementClient = .previewValue
                }
            )
        }
    }
}
