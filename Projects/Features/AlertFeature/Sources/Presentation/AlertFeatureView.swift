import SwiftUI

public struct AlertFeatureView: View {
    @StateObject private var store: AlertFeatureStore

    public init(store: AlertFeatureStore) {
        _store = StateObject(wrappedValue: store)
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("AlertFeature")
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
