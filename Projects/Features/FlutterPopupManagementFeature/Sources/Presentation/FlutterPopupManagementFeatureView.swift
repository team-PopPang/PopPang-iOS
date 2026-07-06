import ComposableArchitecture
import SwiftUI

public struct FlutterPopupManagementFeatureView: View {
    let store: StoreOf<FlutterPopupManagementFeature>

    public init(store: StoreOf<FlutterPopupManagementFeature>) {
        self.store = store
    }

    public var body: some View {
        WithPerceptionTracking {
            VStack(alignment: .leading, spacing: 16) {
                Text(store.title)
                    .font(.title2.weight(.semibold))

                Label(
                    store.isFlutterViewAttached ? "Flutter view attached" : "Flutter view pending",
                    systemImage: store.isFlutterViewAttached ? "checkmark.circle.fill" : "hourglass.circle"
                )
                .font(.headline)

                Text(store.bridgeStatusText)
                    .font(.body)

                Text("This module is the entry point for embedding the Flutter popup management view into the iOS feature flow.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(24)
            .task {
                store.send(.onAppear)
            }
        }
    }
}
