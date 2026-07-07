//
//  FirebaseLogger.swift
//  PopPang
//
//  Created by 김동현 on 12/21/25.
//

import SwiftUI
import FirebaseAnalytics

struct ScreenTrackModifier: ViewModifier {
    let name: String

    func body(content: Content) -> some View {
        content.onAppear {
            Analytics.logEvent(AnalyticsEventScreenView, parameters: [
                AnalyticsParameterScreenName: name,
                AnalyticsParameterScreenClass: name
            ])
        }
    }
}

extension View {
    func trackScreen(_ name: String) -> some View {
        self.modifier(ScreenTrackModifier(name: name))
    }
}

