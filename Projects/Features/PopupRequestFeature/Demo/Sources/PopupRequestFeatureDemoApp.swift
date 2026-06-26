import ComposableArchitecture
import PopupRequestFeature
import SwiftUI

@main
struct PopupRequestFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                PopupRequestFeatureView(
                    store: Store(initialState: PopupRequestFeature.State(userUuid: "demo-user")) {
                        PopupRequestFeature()
                    } withDependencies: {
                        $0.popupRequestClient = .previewValue
                    }
                )
            }
        }
    }
}
