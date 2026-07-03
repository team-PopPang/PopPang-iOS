import ComposableArchitecture
import Domain
import PopupDetailFeature
import SwiftUI

@main
struct PopupDetailFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            PopupDetailFeatureView(
                store: Store(
                    initialState: PopupDetailFeature.State(
                        userUuid: "demo-user",
                        popup: .popupMock
                    )
                ) {
                    PopupDetailFeature()
                } withDependencies: {
                    $0.popupDetailClient = PopupDetailClient(
                        increaseViewCount: { _ in },
                        getPersonalRelatedPopupList: { _, _ in
                            [.popupMock2]
                        },
                        addFavorite: { _, _ in },
                        removeFavorite: { _, _ in },
                        deactivatePopup: { _ in }
                    )
                }
            )
        }
    }
}
