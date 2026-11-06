import ComposableArchitecture
import Domain
import DSKit
import Observation
import SheetKit
import SwiftUI
import UIKit

/// 시트 높이를 담는 작은 객체. 이 값을 읽는 왼쪽 떠 있는 버튼만 프레임마다 다시 그려진다.
@Observable
private final class MapSheetPosition {
    var geometry: BottomSheetGeometry?
}

/// 지도 탭 화면. 피그마 "팝팡 리뉴얼 최종"(2467:10300)의 ① 지도 기본, ② 마커 선택, ③ 목록 펼침, ④ 필터, ⑤ 개별 필터.
public struct MapFeatureView: View {
    @Bindable var store: StoreOf<MapFeature>
    @Environment(\.popPangTabBarStyle) private var tabBarStyle
    @State private var tabBarHeight: CGFloat = 0
    @State private var showLocationPermissionAlert = false
    /// 위치 권한 알림은 화면이 처음 나타날 때 한 번만 띄운다. 탭을 열 때마다 띄우지 않는다.
    @State private var hasHandledPermissionDenied = false
    /// 목록 시트 높이. nil이면 시트를 숨긴다(마커를 골랐을 때).
    @State private var listDetent: BottomSheetDetent? = .medium
    @State private var openMenu: MapMenu?
    @State private var isFilterSheetPresented = false
    @State private var isRegionSheetPresented = false
    @State private var sheetPosition = MapSheetPosition()
    @State private var windowSafeAreaInsets: UIEdgeInsets?
    /// 검색창·칩 아래 끝(화면 좌표). 시트를 끝까지 올렸을 때 목록이 이 아래에서 시작한다.
    @State private var topControlsMaxY: CGFloat = 0

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { proxy in
            let bottomBarHeight = bottomTabBarHeight(safeArea: proxy.safeAreaInsets)
            NaverMapView(popups: store.popups, selectedPopupUuid: store.selectedPopupUuid)
                .ignoresSafeArea()
                // 내 위치 버튼(왼쪽)은 시트 위를 따라 움직인다. 화면 크기 계산에 끼지 않게 overlay에 둔다.
                .overlay(alignment: .bottomLeading) {
                    // 미리보기 카드를 띄우거나 목록을 끝까지 펼치면 숨긴다.
                    if store.selectedPopup == nil, listDetent != .large {
                        MapSideButtonLayer(
                            position: sheetPosition,
                            restingBottomPadding: bottomBarHeight + 64,
                            onLocate: moveToUserLocation
                        )
                    }
                }
                .background {
                    TabBarProxy { _, tabBar in
                        tabBarHeight = tabBar.bounds.height
                    }
                }
                // ③ 목록 펼침: 끝까지 올리면 상태 바(위 safe area)까지 화면 전체를 덮는다. 칩 아래에서 멈추지 않는다.
                // 시트 안 내용은 safe area를 넘지 않게 검색창·칩 아래에서 시작한다.
                .bottomSheet(detent: $listDetent) {
                    MapListSheet(
                        store: store,
                        topPadding: listDetent == .large ? topControlsMaxY : 0,
                        onPopupTap: selectFromList
                    )
                }
                .bottomSheetTopInset(0)
                .ppBottomSheetStyle()
                .onBottomSheetGeometryChange { geometry in
                    sheetPosition.geometry = geometry
                }
                // 검색창·칩과 아래 버튼·미리보기 카드는 시트보다 위에 그린다. 시트를 끝까지 올려도 가려지지 않는다.
                .overlay(alignment: .top) {
                    topControls
                        .padding(.top, proxy.safeAreaInsets.top + 10)
                }
                .overlay(alignment: .bottom) {
                    bottomControls
                        .padding(.bottom, bottomBarHeight + 12)
                        .animation(.easeInOut(duration: 0.2), value: store.selectedPopupUuid)
                }
                .overlayPreferenceValue(MapMenuAnchorKey.self) { anchors in
                    dropdownLayer(anchors: anchors)
                }
            .sheet(isPresented: $isFilterSheetPresented) {
                MapFilterSheet(
                    categories: store.categories,
                    filter: store.filter,
                    onApply: { filter in
                        isFilterSheetPresented = false
                        store.send(.filterApplied(filter))
                        // ④ "팝업 N개 보기" → ③ 목록 펼침
                        listDetent = .large
                    }
                )
                .presentationDetents([.height(520), .large])
                .presentationDragIndicator(.visible)
                .ppSystemSheetStyle()
            }
            .sheet(isPresented: $isRegionSheetPresented) {
                MapRegionSheet(
                    regions: store.regions,
                    selectedRegion: store.selectedRegion,
                    selectedDistrict: store.selectedDistrict,
                    onRegionSelected: { region in
                        store.send(.regionSelected(region))
                        if region.districtList.count <= 1 { isRegionSheetPresented = false }
                    },
                    onDistrictSelected: { district in
                        isRegionSheetPresented = false
                        store.send(.districtSelected(district))
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .ppSystemSheetStyle()
            }
            .alert(Text("위치 권한이 필요합니다", bundle: .module), isPresented: $showLocationPermissionAlert) {
                Button(String(localized: "설정으로 이동", bundle: .module)) {
                    guard let url = URL(string: UIApplication.openSettingsURLString),
                          UIApplication.shared.canOpenURL(url)
                    else { return }
                    UIApplication.shared.open(url)
                }
                Button(String(localized: "취소", bundle: .module), role: .cancel) {}
            } message: {
                Text("주변 팝업스토어를 지도에서 보여주고 내 위치로 이동하려면 위치 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.", bundle: .module)
            }
            .onChange(of: store.selectedPopupUuid) { _, popupUuid in
                // ② 마커를 고르면 목록 시트를 내리고 미리보기 카드를 보인다.
                if popupUuid != nil {
                    openMenu = nil
                    listDetent = nil
                }
            }
            .onAppear {
                configureCallbacks()
                store.send(.onAppear)
            }
            .onDisappear {
                clearCallbacks()
            }
            .onChange(of: proxy.size, initial: true) {
                windowSafeAreaInsets = keyWindowSafeAreaInsets
            }
            .ignoresSafeArea(edges: [.top, .bottom])
        }
    }
}

private extension MapFeatureView {
    var topControls: some View {
        VStack(spacing: 10) {
            MapSearchBar(
                regionTitle: store.regionTitle,
                isOnList: listDetent == .large,
                text: Binding(
                    get: { store.searchText },
                    set: { store.send(.searchTextChanged($0)) }
                ),
                onRegionTap: {
                    openMenu = nil
                    isRegionSheetPresented = true
                }
            )
            .padding(.horizontal, 16)

            MapFilterChipRow(
                filter: store.filter,
                openMenu: openMenu,
                onFilterTap: {
                    openMenu = nil
                    isFilterSheetPresented = true
                },
                onMenuTap: { menu in
                    openMenu = openMenu == menu ? nil : menu
                }
            )
        }
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.frame(in: .global).maxY
        } action: { maxY in
            if abs(topControlsMaxY - maxY) > 0.5 { topControlsMaxY = maxY }
        }
    }

    @ViewBuilder
    var bottomControls: some View {
        if let popup = store.selectedPopup {
            VStack(spacing: 12) {
                MapFloatingPill(
                    title: String(localized: "목록 보기", bundle: .module),
                    systemImage: "list.bullet",
                    style: .light,
                    action: showList
                )

                MapPreviewCard(
                    popup: popup,
                    isFavoriteInFlight: store.favoriteInFlight.contains(popup.popupUuid),
                    onClose: closePreview,
                    onToggleLike: { store.send(.toggleLike(popup)) },
                    onDetail: { store.send(.popupDetailTapped(popup)) }
                )
                .padding(.horizontal, 14)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        } else if listDetent == nil {
            MapFloatingPill(
                title: String(localized: "목록 보기", bundle: .module),
                systemImage: "list.bullet",
                style: .light,
                action: showList
            )
        } else if listDetent == .large {
            // ③ "지도 보기" → ① 지도 기본
            MapFloatingPill(
                title: String(localized: "지도 보기", bundle: .module),
                systemImage: "map",
                style: .dark,
                action: { listDetent = .medium }
            )
        }
    }

    @ViewBuilder
    func dropdownLayer(anchors: [MapMenu: Anchor<CGRect>]) -> some View {
        if let openMenu, let anchor = anchors[openMenu] {
            GeometryReader { geometry in
                let chip = geometry[anchor]
                ZStack(alignment: .topLeading) {
                    // 메뉴 밖을 누르면 닫는다.
                    Color.black.opacity(0.001)
                        .onTapGesture { self.openMenu = nil }

                    MapDropdownMenu(
                        menu: openMenu,
                        categories: store.categories,
                        filter: store.filter,
                        onFilterChange: { filter in
                            self.openMenu = nil
                            store.send(.filterApplied(filter))
                        },
                        onClose: { self.openMenu = nil }
                    )
                    .offset(
                        x: min(max(chip.minX, 16), geometry.size.width - 220 - 16),
                        y: chip.maxY + 6
                    )
                }
            }
        }
    }

    /// 목록에서 팝업을 누르면 상세로 가지 않고 지도에서 그 팝업을 골라 미리보기 카드를 띄운다.
    func selectFromList(_ popup: Popup) {
        NaverMapCoordinator.shared.moveCamera(to: popup)
        store.send(.mapMarkerTapped(popup))
    }

    func showList() {
        store.send(.previewDismissed)
        listDetent = .large
    }

    func closePreview() {
        store.send(.previewDismissed)
        listDetent = .medium
    }

    func moveToUserLocation() {
        NaverMapCoordinator.shared.moveToUserLocation(yOffset: listDetent == nil ? 0 : -300)
    }

    /// 지도 아래쪽을 가리는 탭바 높이. 기존 지도 화면과 같은 계산이다.
    func bottomTabBarHeight(safeArea: EdgeInsets) -> CGFloat {
        guard tabBarStyle == .classic else { return tabBarHeight }
        guard let windowSafeAreaInsets else { return safeArea.bottom }
        return PopPangTabBarMetrics.height + windowSafeAreaInsets.bottom
    }

    var keyWindowSafeAreaInsets: UIEdgeInsets? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
            let window = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return nil
        }
        return window.safeAreaInsets
    }

    func configureCallbacks() {
        NaverMapCoordinator.shared.checkIfLocationServiceIsEnabled()
        NaverMapCoordinator.shared.onMarkerSelected = { popup in
            store.send(.mapMarkerTapped(popup))
        }
        NaverMapCoordinator.shared.onMapTapped = {
            openMenu = nil
            if store.selectedPopupUuid != nil { closePreview() }
        }
        NaverMapCoordinator.shared.onCenterChanged = { coordinate in
            store.send(.mapCenterChanged(coordinate))
        }

        LocationPermissionManager.shared.onPermissionDenied = {
            guard hasHandledPermissionDenied == false else { return }
            hasHandledPermissionDenied = true
            showLocationPermissionAlert = true
            store.send(.locationPermissionDenied)
        }
        LocationPermissionManager.shared.onLocationUpdated = { coordinate in
            store.send(.userLocationChanged(coordinate))
        }
        LocationPermissionManager.shared.requestPermission()
    }

    func clearCallbacks() {
        NaverMapCoordinator.shared.onMarkerSelected = nil
        NaverMapCoordinator.shared.onMapTapped = nil
        NaverMapCoordinator.shared.onCenterChanged = nil
        LocationPermissionManager.shared.onPermissionDenied = nil
        LocationPermissionManager.shared.onLocationUpdated = nil
    }
}

/// 목록 시트 내용 (① 반 높이, ③ 끝까지).
private struct MapListSheet: View {
    @Bindable var store: StoreOf<MapFeature>
    /// 끝까지 올렸을 때 검색창·칩 높이만큼 비우는 위 여백.
    let topPadding: CGFloat
    let onPopupTap: (Popup) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: topPadding)
                .animation(.easeInOut(duration: 0.2), value: topPadding)

            MapListHeader(sort: store.sort) { option in
                store.send(.sortOptionSelected(option))
            }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .bottomSheetDragHandle()

            content
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var content: some View {
        if store.isWaitingForUserLocation || (store.isLoading && store.popups.isEmpty) {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
        } else if let message = store.errorMessage, store.popups.isEmpty {
            Text(message)
                .font(.scdream(.regular, size: 14))
                .foregroundStyle(MapColor.secondaryText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
                .padding(.horizontal, 24)
        } else if store.popups.isEmpty {
            Text("이 지역에 팝업이 없어요.", bundle: .module)
                .font(.scdream(.regular, size: 14))
                .foregroundStyle(MapColor.secondaryText)
                .frame(maxWidth: .infinity)
                .padding(.top, 32)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(store.popups) { popup in
                        MapListPopupCell(
                            popup: popup,
                            isFavoriteInFlight: store.favoriteInFlight.contains(popup.popupUuid),
                            onToggleLike: { store.send(.toggleLike(popup)) }
                        )
                        .onTapGesture {
                            onPopupTap(popup)
                        }

                        if popup.popupUuid != store.popups.last?.popupUuid {
                            Rectangle()
                                .fill(MapColor.divider)
                                .frame(height: 1)
                        }
                    }
                }
                .padding(.horizontal, 16)
                // 시트가 탭바 아래까지 깔리므로 마지막 셀까지 보이게 여백을 둔다.
                .padding(.bottom, 140)
            }
            .padding(.top, 4)
        }
    }
}

/// 왼쪽 내 위치 버튼. 시트 위쪽 끝을 따라 움직이고, 시트를 숨기면 목록 보기 버튼 높이에 멈춘다.
/// 시트를 끝까지 올리면 흐려지며 숨는다.
private struct MapSideButtonLayer: View {
    private static let spacing: CGFloat = 12
    private static let fadeDistance: CGFloat = 150
    private static let hiddenOpacity: CGFloat = 0.05

    let position: MapSheetPosition
    let restingBottomPadding: CGFloat
    let onLocate: () -> Void

    var body: some View {
        let geometry = position.geometry
        let opacity = Self.opacity(for: geometry)

        // 피그마 icon/locate: 조준선 모양.
        MapCircleButton(
            systemImage: "scope",
            accessibilityLabel: Text("내 위치", bundle: .module),
            action: onLocate
        )
        .opacity(opacity)
        .allowsHitTesting(opacity > Self.hiddenOpacity)
        .accessibilityHidden(opacity <= Self.hiddenOpacity)
        .padding(.leading, 16)
        .offset(y: -max((geometry?.height ?? 0) + Self.spacing, restingBottomPadding))
    }

    private static func opacity(for geometry: BottomSheetGeometry?) -> CGFloat {
        guard let geometry else { return 1 }
        guard geometry.maxHeight > 0 else { return 1 }
        return min(max((geometry.maxHeight - geometry.height) / fadeDistance, 0), 1)
    }
}
