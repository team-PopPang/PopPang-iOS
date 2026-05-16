import SwiftUI

public struct MapFeatureView: View {
    @StateObject private var store: MapFeatureStore

    public init(store: MapFeatureStore) {
        _store = StateObject(wrappedValue: store)
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("MapFeature")
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
