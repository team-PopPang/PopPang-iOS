import SwiftUI

public struct AuthFeatureView: View {
    @StateObject private var store: AuthFeatureStore

    public init(store: AuthFeatureStore) {
        _store = StateObject(wrappedValue: store)
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("AuthFeature")
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
