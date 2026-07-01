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
                AuthFeatureView(
                    onLoginSuccess: { user in
                        store.send(.authCompleted(user))
                    }
                )

            case .register:
                RegisterFlowFeatureView(
                    user: store.session.user,
                    onComplete: { user in
                        store.send(.registerCompleted(user))
                    }
                )

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

    let store: StoreOf<OnboardingAuthDestinationFeature>

    var body: some View {
        AuthFeatureView(
            onLoginSuccess: { user in
                store.send(.loginSucceeded(user))
            }
        )
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
