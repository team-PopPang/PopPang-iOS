import AuthFeature
import Core
import Domain
import SwiftUI

@MainActor
public final class AuthFlowCoordinator: Coordinator<
    EmptyRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public weak var parent: (any RootCoordinating)?
    public var pendingRegistrationUser: User?

    public func makeRootView() -> some View {
        AuthFeatureView(
            onLoginSuccess: { [weak self] user in
                self?.parent?.completeAuthentication(user: user)
            }
        )
    }

    public func makeRegisterView() -> some View {
        RegisterFlowFeatureView(
            user: pendingRegistrationUser,
            onComplete: { [weak self] user in
                self?.pendingRegistrationUser = nil
                self?.parent?.completeAuthentication(user: user)
            }
        )
    }
}
