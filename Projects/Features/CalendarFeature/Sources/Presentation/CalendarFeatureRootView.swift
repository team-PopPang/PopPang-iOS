import SwiftUI

public struct CalendarFeatureRootView: View {
    @State private var compound = CalendarFeatureCompound()

    public init() {}

    public var body: some View {
        CalendarFeatureView(compound: compound)
    }
}
