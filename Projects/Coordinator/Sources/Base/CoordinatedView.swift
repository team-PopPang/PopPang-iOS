import SwiftUI

public struct CoordinatedView<C: Coordinator>: View {
    private let coordinator: C

    public init(_ coordinator: C) {
        self.coordinator = coordinator
    }

    public var body: some View {
        @Bindable var navigationController = coordinator.navigationController

        NavigationStack(path: $navigationController.navigationPath) {
            coordinator.rootView
        }
    }
}
