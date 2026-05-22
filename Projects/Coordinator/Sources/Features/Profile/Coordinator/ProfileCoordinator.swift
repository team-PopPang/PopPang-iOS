import Core
import ProfileFeature
import SwiftUI

@MainActor
public protocol ProfileCoordinatorParent: AnyObject {
    func showAuthFlow()
}

@MainActor
public final class ProfileCoordinator: Coordinator<
    EmptyRoute,
    EmptySheetRoute,
    EmptyOverlayRoute,
    EmptyFullScreenRoute,
    EmptyBottomSheetRoute
> {
    public weak var parent: (any ProfileCoordinatorParent)?

    public func makeRootView() -> some View {
        VStack(spacing: 20) {
            ProfileFeatureView()

            Button("로그아웃") {
                self.parent?.showAuthFlow()
            }
            .buttonStyle(.bordered)
        }
        .navigationTitle("Profile")
    }

    @ViewBuilder
    public func buildView(for route: EmptyRoute) -> some View {
        EmptyView()
    }
}
