import SwiftUI

public struct PopupDetailFeatureView: View {
    @StateObject private var store: PopupDetailFeatureStore

    public init(store: PopupDetailFeatureStore) {
        _store = StateObject(wrappedValue: store)
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("PopupDetailFeature")
                .font(.title2)

            if store.state.isLoading {
                ProgressView()
            }

            Button("새로고침") {
                store.send(.refresh)
            }
        }
        .padding()
        .task {
            store.send(.onAppear)
        }
    }
}
