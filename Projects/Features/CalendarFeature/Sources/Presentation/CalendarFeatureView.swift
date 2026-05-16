import SwiftUI

public struct CalendarFeatureView: View {
    @StateObject private var store: CalendarFeatureStore

    public init(store: CalendarFeatureStore) {
        _store = StateObject(wrappedValue: store)
    }

    public var body: some View {
        VStack(spacing: 12) {
            Text("CalendarFeature")
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
