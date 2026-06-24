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
                OnboardingFeatureView(
                    onSkip: {
                        store.send(.onboardingCompleted)
                    },
                    onComplete: {
                        store.send(.onboardingCompleted)
                    }
                )

            case .auth:
                AuthFeatureView(
                    onLoginSuccess: { user in
                        store.send(.authCompleted(user))
                    }
                )

            case .register:
                RegisterFlowFeatureView(
                    user: store.pendingRegistrationUser,
                    onComplete: { user in
                        store.send(.registerCompleted(user))
                    }
                )

            case .main:
                if let mainTabStore = store.scope(state: \.mainTab, action: \.mainTab) {
                    MainTabFeatureView(store: mainTabStore)
                }
            }
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
