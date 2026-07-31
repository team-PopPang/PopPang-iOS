import ComposableArchitecture
import Foundation
import SwiftUI

@main
struct AlertFeatureDemoApp: App {
    private let initialUserUuid = ProcessInfo.processInfo.environment[
        "POPUP_SCROLL_DEMO_USER_UUID"
    ] ?? ""

    var body: some Scene {
        WindowGroup {
            PopupPaginationDemoView(
                store: Store(
                    initialState: PopupPaginationDemoFeature.State(
                        userUuidInput: initialUserUuid
                    )
                ) {
                    PopupPaginationDemoFeature()
                }
            )
        }
    }
}
