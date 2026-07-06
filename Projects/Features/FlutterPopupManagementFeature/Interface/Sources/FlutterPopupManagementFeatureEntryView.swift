import ComposableArchitecture
import SwiftUI
import FlutterPopupManagementFeature

public struct FlutterPopupManagementFeatureEntryView: View {
    public init() {}

    public var body: some View {
        FlutterPopupManagementFeatureView(
            store: Store(initialState: FlutterPopupManagementFeature.State()) {
                FlutterPopupManagementFeature()
            }
        )
    }
}
