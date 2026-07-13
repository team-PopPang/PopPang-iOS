import ComposableArchitecture
import SwiftUI

public struct PopPangRNFeatureView: View {
    @Bindable var store: StoreOf<PopPangRNFeature>

    public init(store: StoreOf<PopPangRNFeature>) {
        self.store = store
    }

    public var body: some View {
        ReactNativeScreen(
            moduleName: "PopPangRNRoot",
            initialProperties: [
                "feature": store.screen.rawValue,
                "userUuid": store.userUuid,
                "nativeEvents": store.screen.nativeEvents,
            ],
            onNativeEvent: { eventName in
                store.send(.nativeEventReceived(eventName))
            }
        )
        .ignoresSafeArea()
        .toolbar(.hidden, for: .navigationBar)
    }
}
