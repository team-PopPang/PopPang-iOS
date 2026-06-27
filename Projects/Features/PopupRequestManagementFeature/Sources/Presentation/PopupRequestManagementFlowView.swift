import ComposableArchitecture
import SwiftUI

public struct PopupRequestManagementFlowView: View {
    let store: StoreOf<PopupRequestManagementFlowFeature>

    public init(store: StoreOf<PopupRequestManagementFlowFeature>) {
        self.store = store
    }

    public var body: some View {
        PopupRequestManagementListView(
            store: store.scope(state: \.list, action: \.list)
        )
    }
}
