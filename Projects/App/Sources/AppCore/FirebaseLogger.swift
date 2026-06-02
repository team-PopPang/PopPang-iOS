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
        guard let analyticsClass = NSClassFromString("FIRAnalytics") as AnyObject? else {
            return
        }

        let parameters: [String: Any] = [
            "firebase_screen": name,
            "firebase_screen_class": name,
        ]

        _ = analyticsClass.perform(
            NSSelectorFromString("logEventWithName:parameters:"),
            with: "screen_view",
            with: parameters
        )
    }
}
