import ADKit
import ComposableArchitecture
import Domain
import DSKit
import Foundation
import PopPangListKit
import SwiftUI

public struct HomeFeatureView: View {
    @Bindable var store: StoreOf<HomeFeature>
    
    // PopPangList에 스크롤 이동 명령을 전달하는 View 전용 객체입니다.
    @State private var listProxy = ListProxy()
    @State private var sheetRoute: HomeSheetRoute?
    @State private var presentedSheetRoute: HomeSheetRoute?
    @State private var nativeAdPlacementDate = Date()
    @StateObject private var nativeAdSlotStore = AdNativeAdSlotStore()
    
    public init(
        store: StoreOf<HomeFeature>
    ) {
        self.store = store
    }
    
    public var body: some View {
        ZStack {
            // MARK: - background
            Color.subWhite
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // MARK: - Navigationbar
                HomeNavigationBar(
                    userUuid: store.userUuid,
                    showsPopupRequestManagement: store.isAdmin,
                    onSearch: { _ in
                        store.send(.searchTapped)
                    },
                    onAlert: { _ in
                        store.send(.alertTapped)
                    },
                    onReport: {
                        store.send(.popupRequestTapped)
                    },
                    onManagePopupRequests: {
                        store.send(.popupRequestManagementTapped)
                    }
                )
                .padding(.bottom, 16)
                
                // MARK: - List
                PopPangList(proxy: listProxy) {
                    
                    // MARK: - Best
                    bestPopupSection(
                        popups: store.bestPopups
                    ) { popup in
                        store.send(.popupSelected(popup))
                    }
                    
                    // MARK: - Coming
                    comingPopupSection(
                        popups: store.comingPopups
                    ) { popup in
                        store.send(.popupSelected(popup))
                    }
                    
                    // MARK: - Grid
                    gridPopupSection { popup in
                        store.send(.popupSelected(popup))
                    }
                }
                .scrollOverlay(
                    // 화면 높이의 1.5배만큼 스크롤하면 위로 가기 버튼을 표시합니다.
                    alignment: .bottomTrailing,
                    visibleWhen: .relativeToViewport(1.5)
                ) { isVisible in
                    HomeTopAnchorButton(isVisible: isVisible) {
                        listProxy.scrollToSection(
                            id: "grid",
                            position: .top,
                            animated: true
                        )
                    }
                }
            }
        }
        .sheet(item: $sheetRoute, onDismiss: handleSheetDismiss) { route in
            switch route {
            case .regionSheet:
                RegionButtonSheet(
                    regions: filterStore.regions,
                    selectedRegion: selectedRegionBinding,
                    selectedDistrict: selectedDistrictBinding,
                    regionTitle: { $0.region },
                    districts: { $0.districtList }
                )
                .presentationDetents([.medium])
                
            case .sortSheet:
                SortButtonSheet(selectedOption: selectedOptionBinding)
                    .presentationDetents([.height(270)])
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .task(id: nativeAdPlacementIDs) {
            nativeAdSlotStore.loadAdIfNeeded(for: nativeAdPlacementIDs)
        }
    }
}

// MARK: - BestPopup Section
extension HomeFeatureView {
    
    private func bestPopupSection(
        popups: [Popup],
        onTap: @escaping (Popup) -> Void
    ) -> PopPangListKit.Section {
        Section(id: "best") {
            For(popups, id: \.popupUuid) { popup in
                BestPopupCell(popup: popup)
            }
            .didSelect { popup in
                onTap(popup)
            }
            .layoutMode(.fitContent(estimatedSize: BestPopupCell.layoutSize))
        }
        .withHeader(item: "bestPopup") { _ in
            HomeBestHeader(nickname: store.nickname)
                .padding(.bottom, 10)
        }
        .headerBackground(UIColor(Color.subWhite))
        .disablesUpdateAnimation()
        .withSectionLayout(
            HorizontalLayout(
                spacing: 15,
                scrollingBehavior: .continuousGroupLeadingBoundary
            )
            .insets(.init(top: 0, leading: .contentPadding, bottom: 50, trailing: .contentPadding))
            .headerPinToVisibleBounds(true)
        )
    }
}

// MARK: - ComingPopup Section
extension HomeFeatureView {
    private func comingPopupSection(
        popups: [Popup],
        onTap: @escaping (Popup) -> Void
    ) -> PopPangListKit.Section {
        Section(id: "comming") {
            For(popups, id: \.popupUuid) { popup in
                ComingPopupCell(popup: popup)
            }
            .didSelect { popup in
                onTap(popup)
            }
            .layoutMode(.fitContent(estimatedSize: ComingPopupCell.layoutSize))
        }
        .withHeader(item: "comingPopup") { _ in
            HomeComingHeader(
                userUuid: store.userUuid,
                popups: store.comingPopups,
                onTap: { _, _ in
                    store.send(.comingPopupsTapped(store.comingPopups))
                }
            )
            .padding(.bottom, 10)
        }
        .headerBackground(UIColor(Color.subWhite))
        .withSectionLayout(
            HorizontalLayout(
                spacing: 15,
                scrollingBehavior: .groupPaging
            )
            .insets(.init(top: 0, leading: .contentPadding, bottom: 65, trailing: .contentPadding))
            .headerPinToVisibleBounds(true)
        )
    }
}

// MARK: - GridPopup Section
extension HomeFeatureView {
    private func gridPopupSection(
        onTap: @escaping (Popup) -> Void
    ) -> PopPangListKit.Section {
        Section(id: "grid") {
            For(gridItems, id: \.id) { item in
                switch item {
                case .content(let popup, _):
                    GridPopupCell(
                        popup: popup,
                        toggleLike: {
                            store.send(
                                .favoriteToggleTapped(
                                    popupUuid: popup.popupUuid
                                )
                            )
                        }
                    )
                    
                case .nativeAd(let slotID):
                    HomeNativeAdGridCell(
                        viewModel: nativeAdSlotStore.viewModel(for: slotID)
                    )
                }
            }
            .didSelect { item in
                guard case let .content(popup, _) = item else { return }
                onTap(popup)
            }
            .layoutMode(
                .flexibleHeight(
                    estimatedHeight: GridPopupCell.estimatedHeight
                )
            )
        }
        .withHeader(item: "gridPopup") { _ in
            HomeFilterHeader(
                store: filterStore,
                onRegionTap: {
                    presentedSheetRoute = .regionSheet
                    sheetRoute = .regionSheet
                },
                onSortTap: {
                    presentedSheetRoute = .sortSheet
                    sheetRoute = .sortSheet
                }
            )
            .padding(.bottom, 10)
        }
        .headerBackground(UIColor(Color.subWhite))
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
                    bottom: 20,
                    trailing: .contentPadding
                )
            )
            .headerPinToVisibleBounds(true)
        )
    }
}

private extension HomeFeatureView {
    var nativeAdPlacements: [AdNativeAdPlacement] {
        AdNativeAdPlacementPolicy.paginatedHomeGridPlacements(
            contentCount: store.gridPopups.count,
            userIdentifier: store.userUuid,
            date: nativeAdPlacementDate
        )
    }
    
    var nativeAdPlacementIDs: [String] {
        nativeAdPlacements.map(\.id)
    }
    
    var loadedNativeAdPlacements: [AdNativeAdPlacement] {
        let loadedSlotIDs = nativeAdSlotStore.loadedSlotIDs(
            in: nativeAdPlacementIDs
        )
        return nativeAdPlacements.filter { loadedSlotIDs.contains($0.id) }
    }
    
    var gridItems: [AdInjectedListItem<Popup>] {
        AdInjectedListItemBuilder.make(
            items: store.gridPopups,
            nativeAdPlacements: loadedNativeAdPlacements,
            id: \.popupUuid
        )
    }
    
    var filterStore: StoreOf<HomeFilterFeature> {
        store.scope(state: \.filter, action: \.filter)
    }
    
    var selectedRegionBinding: Binding<RegionList?> {
        Binding(
            get: { filterStore.selectedRegion },
            set: { region in
                guard let region else { return }
                filterStore.send(.regionSelected(region))
            }
        )
    }
    
    var selectedDistrictBinding: Binding<String?> {
        Binding(
            get: { filterStore.selectedDistrict },
            set: { district in
                guard let district else { return }
                filterStore.send(.districtSelected(district))
            }
        )
    }
    
    var selectedOptionBinding: Binding<SortButton.SortOption> {
        Binding(
            get: { filterStore.selectedOption },
            set: { option in
                filterStore.send(.sortOptionSelected(option))
            }
        )
    }
    
    func handleSheetDismiss() {
        guard let activeSheetRoute = presentedSheetRoute else { return }
        defer { presentedSheetRoute = nil }
        
        switch activeSheetRoute {
        case .regionSheet, .sortSheet:
            store.send(.refreshFilteredPopupList)
        }
    }
}

#Preview {
    HomeFeatureView(
        store: Store(
            initialState: HomeFeature.State(
                user: User(
                    userUuid: "preview-user",
                    uid: "preview-uid",
                    provider: "preview",
                    email: nil,
                    nickname: "홍길동",
                    role: "ADMIN",
                    isAlerted: false,
                    fcmToken: nil,
                    alertKeywordList: nil,
                    recommendList: nil
                )
            )
        ) {
            HomeFeature()
        }
    )
}
