import DSKit
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
                OnboardingCoordinatorView(coordinator: coordinator.onboardingCoordinator)
            case .auth:
                AuthFlowCoordinatorView(coordinator: coordinator.authFlowCoordinator)
            case .register:
                RegisterFlowCoordinatorView(coordinator: coordinator.authFlowCoordinator)
            case .main:
                if let mainTabCoordinator = coordinator.mainTabCoordinator {
                    MainTabCoordinatorView(coordinator: mainTabCoordinator)
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

private struct OnboardingCoordinatorView: View {
    let coordinator: OnboardingCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
        }
    }
}

private struct AuthFlowCoordinatorView: View {
    let coordinator: AuthFlowCoordinator

    var body: some View {
        coordinator.makeRootView()
    }
}

private struct RegisterFlowCoordinatorView: View {
    let coordinator: AuthFlowCoordinator

    var body: some View {
        coordinator.makeRegisterView()
    }
}
