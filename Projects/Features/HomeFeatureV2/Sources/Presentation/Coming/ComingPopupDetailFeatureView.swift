//import ComposableArchitecture
//import Core
//import Domain
//import DSKit
//import ListKit
//import SwiftUI
//
//public struct ComingPopupDetailFeatureView: View {
//    @Environment(\.dismiss) private var dismiss
//    @Bindable var store: StoreOf<ComingPopupDetailFeature>
//    private let onSelectPopup: (String, Popup) -> Void
//
//    public init(
//        store: StoreOf<ComingPopupDetailFeature>,
//        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in }
//    ) {
//        self.store = store
//        self.onSelectPopup = onSelectPopup
//    }
//
//    public init(
//        userUuid: String,
//        popups: [Popup],
//        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in }
//    ) {
//        self.init(
//            store: Store(
//                initialState: ComingPopupDetailFeature.State(
//                    userUuid: userUuid,
//                    popups: popups
//                )
//            ) {
//                ComingPopupDetailFeature()
//            },
//            onSelectPopup: onSelectPopup
//        )
//    }
//
//    public var body: some View {
//        LKList {
//            LKSection(id: "coming-popup-detail") {
//                for popup in store.popups {
//                    LKRow(
//                        popup,
//                        id: \.popupUuid,
//                        reuseIdentifier: "HomeFeature.ListKitGridPopupCell"
//                    ) {
//                        ListKitGridPopupCell(
//                            popup: popup,
//                            isLiked: popup.isFavorited,
//                            cellWidth: Self.gridCellWidth,
//                            toggleLike: {
//                                store.send(.toggleLike(popup))
//                            }
//                        )
//                        .accessibilityElement(children: .ignore)
//                        .accessibilityIdentifier("home_comming_cell")
//                    }
//                    .equatableToken("\(popup.popupUuid)-\(popup.isFavorited)")
//                    .onSelect { _ in
//                        onSelectPopup(store.userUuid, popup)
//                    }
//                }
//            }
//            .sectionLayout(.grid(columns: 2, itemHeight: Self.gridCellHeight, columnSpacing: 15, rowSpacing: 20))
//            .sectionContentInsets(LKEdgeInsets(
//                top: 0,
//                left: .contentPadding,
//                bottom: 0,
//                right: .contentPadding
//            ))
//            .pinnedHeader(background: Color.subWhite)
//        }
//        .listKitStyle(.plain)
//        .updateEngine(.reloadData)
//        .scrollIndicators(.hidden)
//        .contentInsets(LKEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))
////        .overlay {
////            if store.isLoading {
////                HomeFeatureLoadingOverlay()
////            }
////        }
//        .alert("안내", isPresented: isComingPopupErrorPresented) {
//            Button("확인", role: .cancel) {
//                store.send(.errorMessageChanged(nil))
//            }
//        } message: {
//            Text(store.errorMessage ?? "")
//        }
//        .ppBackNavigationBar(title: "오픈 예정 팝업") {
//            dismiss()
//        }
//        .onAppear {
//            store.send(.onAppear)
//        }
//    }
//}
//
//private extension ComingPopupDetailFeatureView {
//    static let gridCellHeight: CGFloat = 302
//
//    static var gridCellWidth: CGFloat {
//        (UIScreen.main.bounds.width - CGFloat.contentPadding * 2 - 15) / 2
//    }
//
//    var isComingPopupErrorPresented: Binding<Bool> {
//        Binding(
//            get: { store.errorMessage != nil },
//            set: { isPresented in
//                if !isPresented {
//                    store.send(.errorMessageChanged(nil))
//                }
//            }
//        )
//    }
//}
//
