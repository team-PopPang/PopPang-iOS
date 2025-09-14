//
//  OnboardingCoordinator.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

enum OnboardingRoute: Hashable {
    case login
    case nicknameSetting
    case selectCategory
}

extension Coordinator where T == OnboardingRoute {
    @ViewBuilder
    func buildView(for route: T) -> some View {
        switch route {
        case .login:
            LoginView()
        case .nicknameSetting:
            NicknameSettingView()
        case .selectCategory:
            EmptyView()
        }
    }
}
