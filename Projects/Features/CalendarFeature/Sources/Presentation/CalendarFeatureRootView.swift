import SwiftUI

public struct CalendarFeatureRootView: View {
    public init() {}

    public var body: some View {
        CalendarFeatureView(
            store: CalendarFeatureStore()
        )
    }
}
