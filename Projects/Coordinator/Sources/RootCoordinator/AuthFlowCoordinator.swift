import AuthFeature
import Core
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

    public func makeRootView() -> some View {
        VStack(spacing: 20) {
            AuthFeatureView()

            Button("메인 플로우로 이동") {
                self.parent?.showMainFlow()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Auth")
    }

    @ViewBuilder
    public func buildView(for route: EmptyRoute) -> some View {
        EmptyView()
    }
}
