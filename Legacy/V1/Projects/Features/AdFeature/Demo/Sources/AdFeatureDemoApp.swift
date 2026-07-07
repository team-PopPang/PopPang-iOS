import SwiftUI
import AdFeatureInterface

@main
struct AdFeatureDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Native Ad")
                        .font(.title2.bold())

                    AdNativeAdEntryView(layout: .grid, reservesSpaceWhileLoading: true)
                        .frame(width: 170, height: 302)

                    AdNativeAdEntryView(layout: .compactBanner, reservesSpaceWhileLoading: true)
                        .frame(height: 112)
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
        }
    }
}
