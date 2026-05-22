import SwiftUI

public struct CalendarFeatureView: View {
    @State private var compound = CalendarFeatureCompound()

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            Text("CalendarFeature")
                .font(.title2)

            if compound.state.isLoading {
                ProgressView()
            }

            Button("새로고침") {
                compound.send(.refresh)
            }
        }
        .padding()
        .task {
            compound.send(.onAppear)
        }
    }
}
