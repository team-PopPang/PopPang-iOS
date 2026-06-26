import AuthFeature
import Coordinator
import DSKit
import OnboardingFeature
import SwiftUI

public struct RootCoordinatorView: View {
    @State private var coordinator: RootCoordinator

    @MainActor
    public init(coordinator: RootCoordinator) {
        _coordinator = State(initialValue: coordinator)
    }

    @MainActor
    public init() {
        _coordinator = State(initialValue: RootCoordinator())
    }

    public var body: some View {
        // @Bindable var coordinator = coordinator

        Group {
            switch coordinator.root {
            case .launch:
                LaunchScene(
                    onContinue: {
                        await coordinator.begin()
                    }
                )
            case .onboarding:
                OnboardingFeatureView()
            case .auth:
                AuthFeatureView()
            case .register:
                RegisterFlowFeatureView(user: coordinator.pendingRegistrationUser)
            case .main:
                MainTabCoordinatorView(coordinator: coordinator)
            }
        }
        .environment(coordinator)
    }
}

private struct LaunchScene: View {
    let onContinue: @MainActor () async -> Void

    var body: some View {
        ZStack {
            DSKitResource.image("Launch")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .task {
            await onContinue()
        }
    }
}
