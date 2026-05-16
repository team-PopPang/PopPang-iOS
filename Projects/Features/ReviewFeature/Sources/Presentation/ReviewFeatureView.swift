import SwiftUI

public struct ReviewFeatureView: View {
    @StateObject private var store: ReviewFeatureStore

    public init(store: ReviewFeatureStore) {
        _store = StateObject(wrappedValue: store)
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("ReviewFeature")
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
