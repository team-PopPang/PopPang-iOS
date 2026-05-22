import Core
import OnboardingFeature
import SwiftUI

@MainActor
public final class OnboardingCoordinator: Coordinator<
    EmptyRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public weak var parent: (any RootCoordinating)?

    public func makeRootView() -> some View {
        OnboardingFeatureView(
            onSkip: { [weak self] in
                self?.parent?.completeOnboarding()
            },
            onComplete: { [weak self] in
                self?.parent?.completeOnboarding()
            }
        )
        .navigationTitle("Onboarding")
    }

    @ViewBuilder
    public func buildView(for route: EmptyRoute) -> some View {
        EmptyView()
    }
}
