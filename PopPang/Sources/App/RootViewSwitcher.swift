//
//  RootViewSwitcher.swift
//  DevNote
//
//  Created by 김동현 on 9/6/25.
//

import SwiftUI

struct RootViewSwitcher: View {
    
    @State private var isReady = false
    @State private var coordinator = Coordinator<OnboardingRoute, SheetRoute>()
    @AppStorage("firstLaunch") private var firstLaunch: Bool = true
    
    enum RootScene {
        case launch
        case onboarding
        case home
    }
    
    private var rootScene: RootScene {
        if !isReady { .launch }
        else { firstLaunch ? .onboarding : .home }
    }
    
    var body: some View {
        Group {
            switch rootScene {
            case .launch:
                LaunchView()
                    .task {
                        await DIContainer.config()
                        try? await Task.sleep(for: .seconds(1))
                        await MainActor.run { self.isReady = true }
                    }
            case .onboarding:
                OnboadringView()
                    .environmentObject(coordinator)
            case .home:
                HomeView()
            }
        }
        .animation(.linear(duration: 0.3), value: rootScene)
    }
}
