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
    /// 위치 권한 알림은 한 번만 띄운다. 탭을 열 때마다 띄우지 않는다.
    @State private var hasShownPermissionAlert = false
    /// 목록 시트 높이. nil이면 시트를 숨긴다(마커를 골랐을 때).
    @State private var listDetent: BottomSheetDetent? = .medium
    @State private var openMenu: MapMenu?
    @State private var isFilterSheetPresented = false
    @State private var isRegionSheetPresented = false
    @State private var sheetPosition = MapSheetPosition()
    @State private var windowSafeAreaInsets: UIEdgeInsets?
    /// 검색창·칩 아래 끝(화면 좌표). 시트를 끝까지 올렸을 때 목록이 이 아래에서 시작한다.
    @State private var topControlsMaxY: CGFloat = 0
    /// 아래 떠 있는 버튼·미리보기 카드의 위쪽 끝(화면 좌표). 시트가 없을 때 지도를 가리는 높이를 잰다.
    @State private var bottomControlsMinY: CGFloat = 0
    /// 화면 아래 끝(화면 좌표).
    @State private var screenBottomY: CGFloat = 0
    /// 탭바 높이(아래 safe area 포함). 시트를 끝까지 내렸을 때 지도를 가리는 높이를 바로 계산하는 데 쓴다.
    @State private var bottomBarHeightValue: CGFloat = 0
    /// 미리보기 카드가 떠 있을 때 지도를 가리는 높이. 한 번 재면 다음에 고를 때 미리 쓴다.
    @State private var cardBottomInset: CGFloat?
    @State private var cardInsetWork: DispatchWorkItem?

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { proxy in
            let bottomBarHeight = bottomTabBarHeight(safeArea: proxy.safeAreaInsets)
            NaverMapView(
                popups: store.popups,
                markerColors: store.markerColors,
                selectedPopupUuid: store.selectedPopupUuid
            )
                .ignoresSafeArea()
                // 내 위치 버튼(왼쪽)은 시트 위를 따라 움직인다. 화면 크기 계산에 끼지 않게 overlay에 둔다.
                .overlay(alignment: .bottomLeading) {
                    // 미리보기 카드를 띄우거나 목록을 끝까지 펼치면 숨긴다.
                    if store.selectedPopup == nil, listDetent != .large {
                        MapSideButtonLayer(
                            position: sheetPosition,
                            // 시트를 끝까지 내리면 가운데 "목록 보기" 버튼(탭바 위 12pt, 높이 38)과 같은 줄 왼쪽에 둔다.
                            restingBottomPadding: bottomBarHeight + Self.floatingPillBottom
                                + (MapFloatingPill.height - MapCircleButton.size) / 2,
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
                    updateMapVisibleInsets()
                }
                // 검색창·칩과 아래 버튼·미리보기 카드는 시트보다 위에 그린다. 시트를 끝까지 올려도 가려지지 않는다.
                .overlay(alignment: .top) {
                    topControls
                        .padding(.top, proxy.safeAreaInsets.top + 10)
                }
                .overlay(alignment: .bottom) {
                    bottomControls
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.frame(in: .global).minY
                        } action: { minY in
                            if abs(bottomControlsMinY - minY) > 0.5 { bottomControlsMinY = minY }
                        }
                        .padding(.bottom, bottomBarHeight + Self.floatingPillBottom)
                        .animation(.easeInOut(duration: 0.2), value: store.selectedPopupUuid)
                }
                .onGeometryChange(for: CGFloat.self) { mapProxy in
                    mapProxy.frame(in: .global).maxY
                } action: { maxY in
                    screenBottomY = maxY
                    // 처음 열 때 다른 값보다 늦게 재질 수 있다. 재지는 순간 보이는 영역을 맞춘다.
                    updateMapVisibleInsets()
                }
                .onAppear {
                    bottomBarHeightValue = bottomBarHeight
                    // 네이버 로고를 탭바 바로 위 오른쪽에 고정한다.
                    updateLogoBaseInset(bottomBarHeight: bottomBarHeight)
                    updateMapVisibleInsets()
                }
                .onChange(of: bottomBarHeight) { _, height in
                    bottomBarHeightValue = height
                    updateLogoBaseInset(bottomBarHeight: height)
                    updateMapVisibleInsets()
                }
                .onChange(of: listDetent) { _, _ in updateMapVisibleInsets() }
                .onChange(of: store.selectedPopupUuid) { _, _ in updateMapVisibleInsets() }
                .onChange(of: bottomControlsMinY) { _, _ in updateMapVisibleInsets() }
                .onChange(of: topControlsMaxY) { _, _ in updateMapVisibleInsets() }
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
    /// 아래 떠 있는 버튼("목록 보기"·"지도 보기")과 미리보기 카드의 탭바 위 여백.
    static let floatingPillBottom: CGFloat = 12

    var topControls: some View {
        VStack(spacing: 10) {
            MapSearchBar(
                regionTitle: store.regionTitle,
                isOnList: listDetent == .large,
                text: Binding(
                    get: { store.searchText },
                    set: { text in
                        // 검색어를 다 지우면 검색 전 목록으로 다시 받는다. 카드를 보는 중이면 검색할 때처럼 카드를 닫고 목록을 연다.
                        let clearsSearch = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            && store.appliedKeyword != nil
                        if clearsSearch, store.selectedPopup != nil {
                            store.send(.previewDismissed)
                            if listDetent == nil { listDetent = .medium }
                        }
                        store.send(.searchTextChanged(text))
                    }
                ),
                onRegionTap: {
                    openMenu = nil
                    isRegionSheetPresented = true
                },
                onSubmit: {
                    // 새로 검색할 때만, 미리보기 카드를 보는 중이면 카드를 닫고 목록을 절반으로 올려 결과를 보여 준다.
                    if store.willSearchOnSubmit {
                        if store.selectedPopup != nil { store.send(.previewDismissed) }
                        if listDetent == nil { listDetent = .medium }
                    }
                    store.send(.searchSubmitted)
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
                    action: { showList(.large) }
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
            // 시트를 끝까지 내렸을 때: 절반 높이로 다시 올린다.
            MapFloatingPill(
                title: String(localized: "목록 보기", bundle: .module),
                systemImage: "list.bullet",
                style: .light,
                action: { showList(.medium) }
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
        // 목록에서 고르면 예전처럼 줌 15로 그 팝업을 보여 준다.
        selectOnMap(popup, zoomLevel: 15)
    }

    /// 팝업을 고르면 미리보기 카드가 뜬다. 카드에 가리는 높이를 먼저 반영해 지도가 한 번에 그 팝업으로 간다.
    /// - Parameter zoomLevel: `nil`이면 지금 줌을 그대로 둔다. 지도에서 마커를 누를 때는 사용자가 맞춰 둔 줌을 바꾸지 않는다.
    func selectOnMap(_ popup: Popup, zoomLevel: Double? = nil) {
        NaverMapCoordinator.shared.moveCamera(
            to: popup,
            topInset: topControlsMaxY > 0 ? topControlsMaxY : nil,
            bottomInset: cardBottomInset ?? Self.estimatedCardInset,
            zoomLevel: zoomLevel
        )
        store.send(.mapMarkerTapped(popup))
    }

    /// 카드 높이를 아직 재지 못했을 때 쓰는 값. 카드·"목록 보기"·탭바를 합친 대략의 높이다.
    static let estimatedCardInset: CGFloat = 315

    /// 미리보기 카드의 "목록 보기"는 끝까지(③), 시트를 내렸을 때의 "목록 보기"는 절반(①)으로 올린다.
    func showList(_ detent: BottomSheetDetent) {
        store.send(.previewDismissed)
        listDetent = detent
    }

    func closePreview() {
        store.send(.previewDismissed)
        listDetent = .medium
    }

    func moveToUserLocation() {
        NaverMapCoordinator.shared.moveToUserLocation()
    }

    /// 지도에서 실제로 보이는 영역(검색창·칩 아래 ~ 시트나 미리보기 카드 위)을 지도에 알린다.
    /// 카메라 중심이 그 영역의 가운데에 오므로, 고른 팝업과 내 위치가 시트나 카드에 가리지 않는다.
    /// 목록을 끝까지 펼친 동안(`.large`)은 지도가 가려져 있으므로 마지막 값을 그대로 둔다.
    func updateMapVisibleInsets() {
        guard screenBottomY > 0, topControlsMaxY > 0 else { return }
        if store.selectedPopup != nil {
            // 카드는 고를 때 미리 반영했다. 카드가 올라오는 애니메이션 동안의 중간 값은 쓰지 않도록 멈춘 뒤 실제 높이를 맞추고 기억한다.
            // 실제 카드 높이가 고를 때 쓴 값과 다르면(처음 고를 때, 글자 크기가 클 때) 그 높이로 고른 팝업을 다시 가운데에 둔다.
            guard bottomControlsMinY > 0 else { return }
            let scheduledUuid = store.selectedPopupUuid
            cardInsetWork?.cancel()
            let work = DispatchWorkItem {
                // 그사이 다른 팝업을 골랐으면 그 팝업의 측정에 맡긴다. 높이는 기다린 뒤의 값으로 다시 잰다.
                guard let popup = store.selectedPopup, popup.popupUuid == scheduledUuid,
                      bottomControlsMinY > 0
                else { return }
                let inset = screenBottomY - bottomControlsMinY
                let top = topControlsMaxY
                cardBottomInset = inset
                // 지도에 실제로 반영된 여백과 비교한다. 지난번에 사용자가 움직여 반영을 건너뛰었으면 다시 맞춘다.
                let coordinator = NaverMapCoordinator.shared
                guard abs(inset - coordinator.contentBottomInset) > 1 || abs(top - coordinator.contentTopInset) > 1 else { return }
                // 그사이 사용자가 지도를 직접 움직였으면 되돌리지 않는다. 높이만 기억해 다음 이동에 쓴다.
                // 여기서 여백을 바꾸면 보이는 지도나 카메라 중심 중 하나가 사용자 모르게 바뀐다.
                guard NaverMapCoordinator.shared.userMovedSinceProgrammaticMove == false else { return }
                NaverMapCoordinator.shared.moveCamera(to: popup, topInset: top, bottomInset: inset, zoomLevel: nil)
            }
            cardInsetWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: work)
        } else if listDetent == nil {
            cardInsetWork?.cancel()
            // 시트를 끝까지 내리면 "목록 보기" 버튼만 남는다. 버튼 위치는 고정이라(탭바 위 12pt, 높이 38pt)
            // 버튼이 나타나길 기다리지 않고 손을 떼는 순간 바로 반영한다.
            guard bottomBarHeightValue > 0 else { return }
            let inset = bottomBarHeightValue + Self.floatingPillBottom + MapFloatingPill.height
            NaverMapCoordinator.shared.setVisibleInsets(top: topControlsMaxY, bottom: inset)
        } else if listDetent == .large {
            // 끝까지 펼친 동안은 지도가 가려져 있다. 지도는 움직이지 않고 절반 높이 여백만 맞춰 두어,
            // 카드 여백이 남은 채로 "지도 보기"를 누르는 일이 없게 한다.
            cardInsetWork?.cancel()
            NaverMapCoordinator.shared.setVisibleInsets(top: topControlsMaxY, bottom: mediumSheetHeight, recenter: false)
        } else if listDetent == .medium {
            cardInsetWork?.cancel()
            let height = mediumSheetHeight
            // 시트는 손을 떼는 순간 멈출 높이를 정하고 `listDetent`를 바꾼다.
            // 다 내려오길 기다리지 않고 그 높이를 바로 반영해, 시트와 지도가 같이 움직이게 한다.
            NaverMapCoordinator.shared.setVisibleInsets(top: topControlsMaxY, bottom: height)
        }
    }

    /// 지도의 고정 아래 여백을 정한다. 네이버 SDK는 로고를 아래 safe area(홈 인디케이터) 위에 두므로,
    /// 탭바 높이에서 그만큼 빼야 로고가 탭바 바로 위에 붙는다. 탭바 높이를 아직 모르면 정하지 않는다.
    func updateLogoBaseInset(bottomBarHeight: CGFloat) {
        guard bottomBarHeight > 0 else { return }
        let safeBottom = (windowSafeAreaInsets ?? keyWindowSafeAreaInsets)?.bottom ?? 0
        NaverMapCoordinator.shared.fixedBottomInset = max(0, bottomBarHeight - safeBottom)
    }

    /// 목록을 절반(`.medium`)에 놓았을 때의 시트 높이. SheetKit은 절반을 시트를 붙인 화면 높이의 0.5로 정하고,
    /// 이 화면은 위 여백을 두지 않아(`bottomSheetTopInset(0)`) 끝까지 올린 높이(`maxHeight`)가 곧 화면 높이다.
    /// 시트 높이를 아직 받지 못했으면 화면 높이로 계산한다(시트를 붙인 지도가 화면 전체라서 같다).
    var mediumSheetHeight: CGFloat {
        let maxHeight = sheetPosition.geometry?.maxHeight ?? 0
        return (maxHeight > 0 ? maxHeight : screenBottomY) * 0.5
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
        NaverMapCoordinator.shared.onMarkerSelected = { popup in
            selectOnMap(popup)
        }
        NaverMapCoordinator.shared.onMapTapped = {
            openMenu = nil
            if store.selectedPopupUuid != nil { closePreview() }
        }
        NaverMapCoordinator.shared.onCenterChanged = { coordinate, byGesture in
            store.send(.mapCenterChanged(coordinate, byGesture: byGesture))
        }

        LocationPermissionManager.shared.onPermissionDenied = {
            // 거부는 매번 알려 가까운순이 오지 않을 위치를 기다리지 않게 한다. 알림만 한 번 띄운다.
            if hasShownPermissionAlert == false {
                hasShownPermissionAlert = true
                showLocationPermissionAlert = true
            }
            store.send(.locationPermissionDenied)
        }
        LocationPermissionManager.shared.onLocationUpdated = { coordinate in
            store.send(.userLocationChanged(coordinate))
        }
        LocationPermissionManager.shared.requestPermission()
    }

    func clearCallbacks() {
        cardInsetWork?.cancel()
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
        // 검색어가 바뀐 조회를 기다리는 동안에도 지난 목록을 검색 결과처럼 보여 주지 않는다.
        if store.isWaitingForUserLocation
            || (store.isLoading && (store.popups.isEmpty || store.requestedKeyword != store.resultKeyword)) {
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
        } else if store.popups.isEmpty, store.lastSearchFailed {
            // 문구 없이 실패한 경우(로그인이 끊김)는 빈 결과 문구를 보여 주지 않는다.
            Color.clear
                .frame(maxWidth: .infinity)
        } else if store.popups.isEmpty {
            Group {
                if store.resultKeyword == nil {
                    Text("이 지역에 팝업이 없어요.", bundle: .module)
                } else {
                    Text("검색 결과가 없어요.", bundle: .module)
                }
            }
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

/// 왼쪽 내 위치 버튼. 시트 위쪽 끝을 따라 움직이고, 시트를 숨기면 "목록 보기" 버튼과 같은 줄에 멈춘다.
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
