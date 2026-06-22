import ADKit
import ComposableArchitecture
import Core
import Domain
import DSKit
import Kingfisher
import ListKit
import SwiftUI
import UIKit

public struct HomeFeatureView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var store: StoreOf<HomeFeatureReducer>
    @State private var currentScrollOffset: CGFloat = 0
    @State private var listProxy = LKListProxy()
    @State private var lastHandledPopupId: String?
    @State private var sheetRoute: HomeSheetRoute?
    @State private var presentedSheetRoute: HomeSheetRoute?
    @StateObject private var nativeAdSlotStore = AdNativeAdSlotStore()

    private let deepLinkStorage: DeepLinkStorage
    // TODO: 코디네이터 패턴은 추후 TCA navigation/state ownership으로 전환 예정
    private let onSelectPopup: (String, Popup) -> Void
    private let onShowAlert: (String) -> Void
    private let onSearch: (String) -> Void
    private let onShowComingPopups: (String, [Popup]) -> Void
    private let onReport: ((String) -> Void)?
    private let onManagePopupRequests: (() -> Void)?
    private let isAdmin: Bool
    private let nativeAdPlacementConfiguration: AdNativeAdPlacementConfiguration
    private let nativeAdCount: Int?

    init(
        store: StoreOf<HomeFeatureReducer>,
        isAdmin: Bool = false,
        nativeAdPlacementConfiguration: AdNativeAdPlacementConfiguration = .homeGrid,
        nativeAdCount: Int? = nil,
        deepLinkStorage: DeepLinkStorage = DeepLinkStorage(store: UserDefaultsStore()),
        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in },
        onShowAlert: @escaping (String) -> Void = { _ in },
        onSearch: @escaping (String) -> Void = { _ in },
        onShowComingPopups: @escaping (String, [Popup]) -> Void = { _, _ in },
        onReport: ((String) -> Void)? = nil,
        onManagePopupRequests: (() -> Void)? = nil
    ) {
        _store = State(initialValue: store)
        self.isAdmin = isAdmin
        self.nativeAdPlacementConfiguration = nativeAdPlacementConfiguration
        self.nativeAdCount = nativeAdCount
        self.deepLinkStorage = deepLinkStorage
        self.onSelectPopup = onSelectPopup
        self.onShowAlert = onShowAlert
        self.onSearch = onSearch
        self.onShowComingPopups = onShowComingPopups
        self.onReport = onReport
        self.onManagePopupRequests = onManagePopupRequests
    }

    public init(
        userUuid: String = "demo-user",
        nickname: String = "닉네임",
        isAdmin: Bool = false,
        nativeAdPlacementConfiguration: AdNativeAdPlacementConfiguration = .homeGrid,
        nativeAdCount: Int? = nil,
        deepLinkStorage: DeepLinkStorage = DeepLinkStorage(store: UserDefaultsStore()),
        onSelectPopup: @escaping (String, Popup) -> Void = { _, _ in },
        onShowAlert: @escaping (String) -> Void = { _ in },
        onSearch: @escaping (String) -> Void = { _ in },
        onShowComingPopups: @escaping (String, [Popup]) -> Void = { _, _ in },
        onReport: ((String) -> Void)? = nil,
        onManagePopupRequests: (() -> Void)? = nil
    ) {
        self.init(
            store: Store(
                initialState: HomeFeatureReducer.State(
                    userUuid: userUuid,
                    nickname: nickname
                )
            ) {
                HomeFeatureReducer()
            },
            isAdmin: isAdmin,
            nativeAdPlacementConfiguration: nativeAdPlacementConfiguration,
            nativeAdCount: nativeAdCount,
            deepLinkStorage: deepLinkStorage,
            onSelectPopup: onSelectPopup,
            onShowAlert: onShowAlert,
            onSearch: onSearch,
            onShowComingPopups: onShowComingPopups,
            onReport: onReport,
            onManagePopupRequests: onManagePopupRequests
        )
    }

    public var body: some View {
        ZStack {
            Color.subWhite
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HomeNavigationBar(
                    userUuid: store.userUuid,
                    showsPopupRequestManagement: isAdmin && onManagePopupRequests != nil,
                    onSearch: { userUuid in
                        onSearch(userUuid)
                    },
                    onAlert: { userUuid in
                        onShowAlert(userUuid)
                    },
                    onReport: {
                        if let onReport {
                            onReport(store.userUuid)
                        }
                    },
                    onManagePopupRequests: {
                        onManagePopupRequests?()
                    }
                )

                LKList {
                    LKSection(id: "best") {
                        for popup in store.bestPopups {
                            LKRow(
                                popup,
                                id: \.popupUuid,
                                reuseIdentifier: "HomeFeature.ListKitBestPopupCell"
                            ) {
                                ListKitBestPopupCell(popup: popup)
                            }
                            .onSelect { _ in
                                onSelectPopup(store.userUuid, popup)
                            }
                        }
                    } header: {
                        HomeBestHeader(nickname: store.nickname)
                            .padding(.bottom, 10)
                    }
                    .sectionLayout(.horizontal(width: 194, height: 271))
                    .scrollAxis(.horizontal)
                    .orthogonalScrollingBehavior(.continuousGroupLeadingBoundary)
                    .itemSpacing(15)
                    .sectionContentInsets(LKEdgeInsets(
                        top: 0,
                        left: .contentPadding,
                        bottom: 50,
                        right: .contentPadding
                    ))
                    .pinnedHeader(background: Color.subWhite)

                    LKSection(id: "coming") {
                        for popup in store.comingPopups {
                            LKRow(
                                popup,
                                id: \.popupUuid,
                                reuseIdentifier: "HomeFeature.ListKitComingPopupCell"
                            ) {
                                ListKitComingPopupCell(popup: popup)
                            }
                            .onSelect { _ in
                                onSelectPopup(store.userUuid, popup)
                            }
                        }
                    } header: {
                        HomeComingHeader(
                            userUuid: store.userUuid,
                            popups: store.comingPopups,
                            onTap: { _, _ in
                                onShowComingPopups(
                                    store.userUuid,
                                    store.comingPopups
                                )
                            }
                        )
                        .padding(.bottom, 10)
                    }
                    .sectionLayout(.horizontal(width: 283, height: 138))
                    .scrollAxis(.horizontal)
                    .orthogonalScrollingBehavior(.groupPaging)
                    .itemSpacing(15)
                    .sectionContentInsets(LKEdgeInsets(
                        top: 0,
                        left: .contentPadding,
                        bottom: 65,
                        right: .contentPadding
                    ))
                    .pinnedHeader(background: Color.subWhite)

                    LKSection(id: "grid") {
                        for item in AdInjectedListItemBuilder.make(
                            items: store.gridPopups,
                            nativeAdPlacements: loadedNativeAdPlacements,
                            id: { $0.popupUuid }
                        ) {
                            switch item {
                            case .content(let popup, _):
                                LKRow(
                                    popup,
                                    id: \.popupUuid,
                                    reuseIdentifier: "HomeFeature.ListKitGridPopupCell"
                                ) {
                                    ListKitGridPopupCell(
                                        popup: popup,
                                        isLiked: isLiked(popup: popup),
                                        cellWidth: Self.gridCellWidth,
                                        toggleLike: { store.send(.toggleLike(popup)) }
                                    )
                                }
                                .equatableToken("\(popup.popupUuid)-\(isLiked(popup: popup))")
                                .onSelect { _ in
                                    onSelectPopup(store.userUuid, popup)
                                }

                            case .nativeAd(let slotID):
                                LKRow(
                                    id: item.id,
                                    reuseIdentifier: "HomeFeature.AdNativeAdGridCell"
                                ) {
                                    AdNativeAdView(
                                        viewModel: nativeAdSlotStore.viewModel(for: slotID),
                                        layout: .grid
                                    )
                                }
                                .equatableToken(item.id)
                            }
                        }
                    } header: {
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
                    .sectionLayout(.grid(columns: 2, itemHeight: Self.gridCellHeight, columnSpacing: 15, rowSpacing: 20))
                    .sectionContentInsets(LKEdgeInsets(
                        top: 0,
                        left: .contentPadding,
                        bottom: 0,
                        right: .contentPadding
                    ))
                    .pinnedHeader(background: Color.subWhite)
                }
                .listKitStyle(.plain)
                .updateEngine(.reloadData)
                .scrollIndicators(.hidden)
                .contentInsets(LKEdgeInsets(top: 0, left: 0, bottom: 50, right: 0))
                .listProxy(listProxy)
                .onScroll { context in
                    currentScrollOffset = context.contentOffset.y
                }
                .overlay(alignment: Alignment.bottomTrailing) {
                    HomeTopAnchorButton(isVisible: currentScrollOffset > 650) {
                        listProxy.scrollToSection(id: "grid", position: .top, animated: true)
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
        .overlay {
            if store.isLoading {
                HomeFeatureLoadingOverlay()
            }
        }
        .alert("안내", isPresented: isErrorPresented) {
            Button("확인", role: .cancel) {
                store.send(.errorMessageChanged(nil))
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    handleDeeplinkIfNeeded()
                }
            }
        }
    }
}

private extension HomeFeatureView {
    static let gridCellHeight: CGFloat = 302

    static var gridCellWidth: CGFloat {
        (UIScreen.main.bounds.width - CGFloat.contentPadding * 2 - 15) / 2
    }

    var nativeAdPlacements: [AdNativeAdPlacement] {
        AdNativeAdPlacementPolicy.placements(
            contentCount: store.gridPopups.count,
            userIdentifier: store.userUuid,
            adCount: nativeAdCount,
            configuration: nativeAdPlacementConfiguration
        )
    }

    var nativeAdPlacementIDs: [String] {
        nativeAdPlacements.map(\.id)
    }

    var loadedNativeAdPlacements: [AdNativeAdPlacement] {
        let loadedSlotIDs = nativeAdSlotStore.loadedSlotIDs(in: nativeAdPlacementIDs)
        return nativeAdPlacements.filter { loadedSlotIDs.contains($0.id) }
    }

    var filterStore: StoreOf<HomeFilterReducer> {
        store.scope(state: \.filter, action: \.filter)
    }

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

struct HomeFeatureLoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.mainBlack.opacity(0.08)
                .ignoresSafeArea()

            ProgressView()
                .controlSize(.large)
                .padding(20)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct HomeNavigationBar: View {
    let userUuid: String
    let showsPopupRequestManagement: Bool
    let onSearch: (String) -> Void
    let onAlert: (String) -> Void
    let onReport: () -> Void
    let onManagePopupRequests: () -> Void

    var body: some View {
        CustomNavigationBar {
            Text("POP PANG")
                .ppStyleFont(.scdream(.black, size: 20))
                .foregroundStyle(Color.mainOrange)

            Spacer()

            IconButton(image: "SearchDark", imageSize: 25) {
                onSearch(userUuid)
            }
            .accessibilityIdentifier("home_search_button")

            IconButton {
                onAlert(userUuid)
            }

            HomeReportButton {
                onReport()
            }
            .accessibilityIdentifier("home_popup_report_button")

            if showsPopupRequestManagement {
                HomePopupRequestManagementButton {
                    onManagePopupRequests()
                }
                .accessibilityIdentifier("home_popup_request_management_button")
            }
        }
        .padding(.bottom, 15)
    }
}

private struct HomeReportButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.subBlack)
                .frame(width: 21, height: 21)
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .offset(y: -1.5)
        .buttonStyle(PressableButtonStyle())
    }
}

private struct HomePopupRequestManagementButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "tray.full")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color.subBlack)
                .frame(width: 21, height: 21)
                .padding(10)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .contentShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct HomeTopAnchorButton: View {
    let isVisible: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            DSKitResource.image("TopAnchor")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.mainBlack)
                .frame(width: 52, height: 52)
                .background {
                    Circle()
                        .fill(Color.subWhite)
                        .applyShadow(
                            color: Color.subBlack,
                            alpha: 0.05,
                            x: 0,
                            y: 4,
                            blur: 4
                        )
                }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .opacity(isVisible ? 1 : 0)
    }
}

private extension HomeFeatureView {
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
        guard let presentedSheetRoute else { return }
        defer { self.presentedSheetRoute = nil }

        switch presentedSheetRoute {
        case .regionSheet, .sortSheet:
            store.send(.refreshFilteredPopupList)
        }
    }

    func isLiked(popup: Popup) -> Bool {
        store.gridPopups.first { $0.popupUuid == popup.popupUuid }?.isFavorited ?? popup.isFavorited
    }
}

private extension HomeFeatureView {
    func handleDeeplinkIfNeeded() {
        Task {
            guard let popupId = deepLinkStorage.loadPopupID(),
                  lastHandledPopupId != popupId
            else {
                return
            }

            while store.bestPopups.isEmpty &&
                store.comingPopups.isEmpty &&
                store.gridPopups.isEmpty {
                try? await Task.sleep(nanoseconds: 200_000_000)
            }

            await MainActor.run {
                moveToPopupDetailIfExists(popupId: popupId)
                deepLinkStorage.removePopupID()
                lastHandledPopupId = popupId
            }
        }
    }

    func moveToPopupDetailIfExists(popupId: String) {
        let allPopups = store.bestPopups
            + store.comingPopups
            + store.gridPopups

        if let targetPopup = allPopups.first(where: { $0.popupUuid == popupId }) {
            onSelectPopup(store.userUuid, targetPopup)
        }
    }
}

#if DEBUG
#Preview("HomeFeatureView") {
    HomeFeatureView(
        store: Store(
            initialState: HomeFeatureReducer.State(
                userUuid: "preview-user",
                nickname: "팝팡"
            )
        ) {
            HomeFeatureReducer()
        } withDependencies: {
            $0.homePopupClient = .previewValue
        }
    )
}
#endif
