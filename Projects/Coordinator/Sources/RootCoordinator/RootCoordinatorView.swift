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
                    onContinue: coordinator.showOnboarding
                )
            case .onboarding:
                OnboardingCoordinatorView(coordinator: coordinator.onboardingCoordinator)
            case .auth:
                AuthFlowCoordinatorView(coordinator: coordinator.authFlowCoordinator)
            case .main:
                MainTabCoordinatorView(coordinator: coordinator.mainTabCoordinator)
            }
        }
    }
}

private struct LaunchScene: View {
    let onContinue: @MainActor () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("PopPang")
                .font(.largeTitle.bold())

            Text("루트 코디네이터 시작 화면")
                .foregroundStyle(.secondary)

            Button("온보딩으로 이동") {
                onContinue()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
}

private struct OnboardingCoordinatorView: View {
    let coordinator: OnboardingCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
        } sheetView: { route in
            EmptyView()
        } overlayView: { route in
            EmptyView()
        } fullScreenView: { route in
            EmptyView()
        }
    }
}

private struct AuthFlowCoordinatorView: View {
    let coordinator: AuthFlowCoordinator

    var body: some View {
        CoordinatorContainer(coordinator: coordinator) {
            coordinator.makeRootView()
        } destination: { route in
            coordinator.buildView(for: route)
        } sheetView: { route in
            EmptyView()
        } overlayView: { route in
            EmptyView()
        } fullScreenView: { route in
            EmptyView()
        }
    }
}
