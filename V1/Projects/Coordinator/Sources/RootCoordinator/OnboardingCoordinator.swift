import AuthFeature
import Core
import OnboardingFeature
import SwiftUI

public enum OnboardingRoute: Hashable {
    case login
}

@MainActor
public final class OnboardingCoordinator: Coordinator<
    OnboardingRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public weak var parent: (any RootCoordinating)?

    public func makeRootView() -> some View {
        OnboardingFeatureView(
            onSkip: { [weak self] in
                self?.showLogin()
            },
            onComplete: { [weak self] in
                self?.showLogin()
            }
        )
    }

    public func showLogin() {
        parent?.markOnboardingCompleted()
        push(.login)
    }

    @ViewBuilder
    public func buildView(for route: OnboardingRoute) -> some View {
        switch route {
        case .login:
            AuthFeatureView(
                onLoginSuccess: { [weak self] user in
                    self?.parent?.completeAuthentication(user: user)
                }
            )
        }
    }
}
