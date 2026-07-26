import ComposableArchitecture
import Domain
import DSKit
import PopPangListKit
import SwiftUI

public struct ComingPopupDetailFeatureView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var store: StoreOf<ComingPopupDetailFeature>
    private let onSelectPopup: (String, Popup) -> Void

    public init(
        store: StoreOf<ComingPopupDetailFeature>,
        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in }
    ) {
        self.store = store
        self.onSelectPopup = onSelectPopup
    }

    public var body: some View {
        PopPangList {
            Section(id: "coming-popup-detail") {
                For(store.popups, id: \.popupUuid) { popup in
                    GridPopupCell(
                        popup: popup,
                        toggleLike: {
                            store.send(.toggleLike(popup))
                        }
                    )
                }
                .didSelect { popup in
                    onSelectPopup(store.userUuid, popup)
                }
                .layoutMode(
                    .flexibleHeight(
                        estimatedHeight: GridPopupCell.estimatedHeight
                    )
                )
            }
            .withSectionLayout(
                VerticalGridLayout(
                    numberOfItemsInRow: 2,
                    itemSpacing: 15,
                    lineSpacing: 20
                )
                .insets(
                    .init(
                        top: 0,
                        leading: .contentPadding,
                        bottom: 0,
                        trailing: .contentPadding
                    )
                )
                .headerPinToVisibleBounds(true)
            )
        }
        .scrollIndicators(.hidden)
        .alert("안내", isPresented: isErrorPresented) {
            Button("확인", role: .cancel) {
                store.send(.errorMessageChanged(nil))
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .ppBackNavigationBar(title: "오픈 예정 팝업") {
            dismiss()
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

private extension ComingPopupDetailFeatureView {
    var isErrorPresented: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    store.send(.errorMessageChanged(nil))
                }
            }
        )
    }
}
