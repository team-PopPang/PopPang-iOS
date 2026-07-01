import AuthFeature
import ComposableArchitecture
import DSKit
import OnboardingFeature
import SwiftUI

struct AppRootFlowView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        Group {
            switch store.destination {
            case .launch:
                LaunchScene {
                    store.send(.launchTask)
                }

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

private struct LaunchScene: View {
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            DSKitResource.image("Launch")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .task {
            onContinue()
        }
    }
}
