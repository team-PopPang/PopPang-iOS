import Coordinator
import DSKit
import SwiftUI

struct AppRootFlowView: View {
    @State private var coordinator: RootCoordinator

    @MainActor
    init(coordinator: RootCoordinator) {
        _coordinator = State(initialValue: coordinator)
    }

    var body: some View {
        @Bindable var coordinator = coordinator

        Group {
            switch coordinator.destination {
            case .launch:
                LaunchScene(
                    onContinue: {
                        await coordinator.begin()
                    }
                )
            case .onboarding:
                OnboardingFlowView(coordinator: coordinator.onboardingCoordinator)
            case .auth:
                coordinator.authFlowCoordinator.makeRootView()
            case .register:
                coordinator.authFlowCoordinator.makeRegisterView()
            case .main:
                if let mainTabCoordinator = coordinator.mainTabCoordinator {
                    MainTabFeatureHost(
                        session: mainTabCoordinator.session,
                        selectedTab: mainTabCoordinator.selectedTab,
                        onLogout: {
                            coordinator.logout()
                        }
                    )
                    .id(mainTabCoordinator.session)
                }
            }
        }
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

private struct OnboardingFlowView: View {
    let coordinator: OnboardingCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
        }
    }
}
