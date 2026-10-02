import AuthFeature
import ComposableArchitecture
import DSKit
import MaintenanceFeature
import OnboardingFeature
import MainTabFeature
import SwiftUI

struct AppRootFlowView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            switch store.destination {
            case .launch:
                AppLaunchScene {
                    store.send(.launchTask)
                }

            case .maintenance:
                MaintenanceFeatureView(
                    reason: store.maintenanceReason,
                    isRetrying: store.isCheckingServerHealth,
                    onRetry: {
                        store.send(.maintenanceRetryTapped)
                    }
                )

            case .onboarding:
                NavigationStack(path: $store.scope(state: \.onboardingPath, action: \.onboardingPath)) {
                    OnboardingFeatureView(store: store.scope(state: \.onboarding, action: \.onboarding))
                } destination: { pathStore in
                    switch pathStore.state {
                    case .auth:
                        if let authStore = pathStore.scope(state: \.auth, action: \.auth) {
                            OnboardingAuthScene(store: authStore)
                        }
                    }
                }
                .onDisappear {
                    store.send(.onboardingRootDidDisappear)
                }

            case .auth:
                AuthFeatureView(store: store.scope(state: \.auth, action: \.auth))

            case .register:
                if let registerStore = store.scope(state: \.registerFlow, action: \.registerFlow) {
                    RegisterFlowFeatureView(store: registerStore)
                } else {
                    EmptyView()
                }

            case .main:
                if let mainTabStore = store.scope(state: \.mainTab, action: \.mainTab) {
                    MainTabFeatureView(store: mainTabStore)
                        .onDisappear {
                            store.send(.mainTabViewDidDisappear)
                        }
                } else {
                    EmptyView()
                }
            }
        }
    }
}

private struct OnboardingAuthScene: View {
    @Environment(\.dismiss) private var dismiss

    let store: StoreOf<AuthFeature>

    var body: some View {
        AuthFeatureView(store: store)
        .ppBackNavigationBar(title: "") {
            dismiss()
        }
    }
}

private struct AppLaunchScene: View {
    let onContinue: () -> Void

    /// 앱 시작 확인이 오래 걸릴 때만 로딩 표시를 보여 준다
    @State private var showsProgress = false

    var body: some View {
        ZStack {
            DSKitResource.image("Launch")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            if showsProgress {
                VStack {
                    Spacer()

                    ProgressView()
                        .padding(.bottom, 80)
                }
            }
        }
        .task {
            onContinue()

            // 서버 확인이 1.5초를 넘기면 멈춘 것처럼 보이지 않도록 로딩 표시를 띄운다
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            showsProgress = true
        }
    }
}
