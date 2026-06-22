import FirebaseAnalytics
import Foundation
import SwiftUI

struct ScreenTrackModifier: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content.onAppear {
            FirebaseAnalyticsBridge.logScreenView(name)
        }
    }
}

extension View {
    func trackScreen(_ name: String) -> some View {
        modifier(ScreenTrackModifier(name: name))
    }
}

private enum FirebaseAnalyticsBridge {
    static func logScreenView(_ name: String) {
        Analytics.logEvent("screen_view", parameters: [
            "firebase_screen": name,
            "firebase_screen_class": name,
        ])
    }
}
