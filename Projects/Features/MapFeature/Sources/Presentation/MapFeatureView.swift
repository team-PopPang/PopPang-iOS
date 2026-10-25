import ComposableArchitecture
import Domain
import DSKit
import Observation
import SheetKit
import SwiftUI
import UIKit

/// 두 번째 시트에 띄우는 내용.
private enum MapSecondSheet: Identifiable {
    case region
    case sort
    case detail(Popup)

    var id: String {
        switch self {
        case .region:
            "region"
        case .sort:
            "sort"
        case .detail(let popup):
            "detail-\(popup.id)"
        }
    }
}

/// 시트 높이를 담는 작은 객체. 이 값을 읽는 내 위치 버튼만 프레임마다 다시 그려진다.
/// 화면의 `@State`에 바로 담으면 끄는 동안 지도 화면 전체가 프레임마다 다시 그려진다.
@Observable
private final class MapSheetPosition {
    var geometry: BottomSheetGeometry?
}

public struct MapFeatureView: View {
    @Bindable var store: StoreOf<MapFeature>
    @Environment(\.popPangTabBarStyle) private var tabBarStyle
    @State private var tabBarHeight: CGFloat = 0
    @State private var searchBarFrame: CGRect = .zero
    @State private var showLocationPermissionAlert = false
    // 시트는 이 화면 안에서만 쓰는 상태라 리듀서가 아니라 view에 둔다.
    @State private var firstSheetDetent: BottomSheetDetent? = .medium
    @State private var secondSheet: MapSecondSheet?
    @State private var secondSheetDetent: BottomSheetDetent = .medium
    @State private var sheetPosition = MapSheetPosition()
    /// 창의 safe area. 키보드가 올라와도 바뀌지 않는다. 화면을 그리는 도중에는 읽지 않고 `onChange`에서 읽어 둔다.
    @State private var windowSafeAreaInsets: UIEdgeInsets?

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        // 화면을 그리는 도중에는 창(`UIWindow`)의 safe area를 읽지 않는다.
        // 읽으면 UIKit이 상태 바 설정을 SwiftUI에 되물어 그래프 순환이 생기고,
        // 순환이 끊긴 자리의 화면이 갱신되지 않는다(시트를 숨겨도 목록 보기 버튼이 나타나지 않았다).
        GeometryReader { proxy in
            let bottomBarHeight = bottomTabBarHeight(safeArea: proxy.safeAreaInsets)
            ZStack(alignment: .trailing) {
                NaverMapView(popups: store.mapPopups)
                    .ignoresSafeArea()

                topControls
                    .frame(maxHeight: .infinity, alignment: .top)
                    .padding(.top, proxy.safeAreaInsets.top + 10)
                    .padding(.horizontal, 15)

                if firstSheetDetent == nil {
                    listButton
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .padding(.bottom, 20 + bottomBarHeight)
                }
            }
            // 내 위치 버튼은 하나만 둔다. 시트 위를 따라 움직이고, 시트를 숨기면 목록 보기 버튼 오른쪽에 멈춘다.
            // ZStack 안에 두면 시트 높이로 정한 버튼 위치가 화면 크기 계산에 끼어든다. 그러면 소수점 끝자리 차이로
            // 화면 높이가 바뀌고, 시트 높이와 버튼 위치가 다시 바뀌는 고리가 끝없이 돌아 앱이 멈췄다.
            // overlay는 화면 크기를 바꾸지 않으므로 여기에 둔다. 시트는 뒤에 붙이므로 버튼보다 위에 그려진다.
            .overlay(alignment: .bottomTrailing) {
                MapLocationButtonLayer(
                    position: sheetPosition,
                    restingBottomPadding: 20 + bottomBarHeight,
                    action: moveToUserLocation
                )
            }
            .background {
                TabBarProxy { _, tabBar in
                    tabBarHeight = tabBar.bounds.height
                }
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
            .bottomSheet(detent: $firstSheetDetent) {
                FirstSheetView(
                    store: store,
                    onSortTap: {
                        openSecondSheet(.sort)
                    },
                    onPopupTap: { index, popup in
                        moveCamera(to: popup, markerIndex: index)
                        openSecondSheet(.detail(popup))
                    },
                    onToggleLike: { popup in
                        store.send(.toggleLike(popup))
                    }
                )
            }
            .bottomSheet(item: $secondSheet, detent: $secondSheetDetent) { sheet in
                SecondSheetView(
                    store: store,
                    sheet: sheet,
                    onDismiss: {
                        secondSheet = nil
                    },
                    onRegionSelected: { region in
                        store.send(.regionSelected(region))
                    },
                    onDistrictSelected: { district in
                        secondSheet = nil
                        store.send(.districtSelected(district))
                    },
                    onSortSelected: { option in
                        secondSheet = nil
                        store.send(.sortOptionSelected(option))
                    },
                    onPopupDetailTap: { popup in
                        store.send(.popupDetailTapped(popup))
                    }
                )
            }
            // 시트를 끝까지 올려도 검색창은 보이게 한다.
            .bottomSheetTopInset(searchBarFrame.maxY + 20)
            .ppBottomSheetStyle()
            .onBottomSheetGeometryChange { geometry in
                sheetPosition.geometry = geometry
            }
            .onChange(of: secondSheetDetent) { _, detent in
                // 두 번째 시트를 끌면 뒤에 있는 첫 번째 시트도 같은 높이로 따라간다.
                firstSheetDetent = detent
            }
            .onAppear {
                configureCallbacks()
                store.send(.onAppear)
            }
            .onDisappear {
                clearCallbacks()
            }
            // 창의 safe area는 그리기가 끝난 뒤 읽어 둔다. 키보드가 올라와 크기가 바뀌어도 값은 그대로다.
            .onChange(of: proxy.size, initial: true) {
                windowSafeAreaInsets = keyWindowSafeAreaInsets
            }
            .ignoresSafeArea(edges: [.top, .bottom])
        }
    }
}

private extension MapFeatureView {
    var topControls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 0) {
                MapRegionButton(text: store.selectedRegion?.region ?? "전체") {
                    openSecondSheet(.region)
                }

                Divider()
                    .frame(width: 1, height: 20)
                    .background(Color.mainGray8)

                MapSearchTextField(
                    placeholder: String(localized: "궁금한 팝업을 검색해보세요", bundle: .module),
                    text: searchTextBinding
                )
            }
            .background {
                GeometryReader { geo in
                    Color.subWhite
                        .cornerRadius(3)
                        .onAppear {
                            updateSearchBarFrame(geo.frame(in: .global))
                        }
                        .onChange(of: geo.frame(in: .global)) { _, newFrame in
                            updateSearchBarFrame(newFrame)
                        }
                }
            }

            TrendingCategoryScrollView(
                categories: store.categories,
                selectedCategoryId: store.selectedCategoryId
            ) { category in
                store.send(.categoryTapped(category))
            }
        }
    }

    func moveToUserLocation() {
        if firstSheetDetent == nil {
            NaverMapCoordinator.shared.moveToUserLocation()
        } else {
            NaverMapCoordinator.shared.moveToUserLocation(yOffset: -300)
        }
    }

    var listButton: some View {
        Button {
            firstSheetDetent = .medium
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "list.bullet")
                    .foregroundStyle(Color.mainBlack)
                    .frame(width: 12, height: 12)
                    .padding(.bottom, 3)

                Text("목록 보기", bundle: .module)
                    .foregroundStyle(Color.mainBlack)
                    .font(.scdream(.regular, size: 12))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color.subWhite)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
        .applyShadow(color: Color.mainBlack, alpha: 0.5, x: 0, y: 1, blur: 3)
    }

    var searchTextBinding: Binding<String> {
        Binding(
            get: { store.searchText },
            set: { store.send(.searchTextChanged($0)) }
        )
    }

    /// 지도 아래쪽을 가리는 탭바 높이. 홈 인디케이터 영역을 포함한다.
    /// 클래식 탭바는 시스템 탭바를 숨기고 하단 safe area 위에 붙으므로, 창의 하단 safe area에 그 높이를 더한다.
    /// GeometryReader의 하단 safe area는 키보드가 올라오면 키보드 높이가 되므로 창 값을 쓴다.
    /// 창 값을 읽기 전 첫 화면에서만 GeometryReader 값을 쓴다. 키보드가 없으면 두 값이 같다.
    func bottomTabBarHeight(safeArea: EdgeInsets) -> CGFloat {
        guard tabBarStyle == .classic else { return tabBarHeight }
        guard let windowSafeAreaInsets else { return safeArea.bottom }
        return PopPangTabBarMetrics.height + windowSafeAreaInsets.bottom
    }

    /// 키 윈도우의 safe area. 화면을 그리는 도중에는 부르지 않는다.
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
        NaverMapCoordinator.shared.onMarkerSelected = { _, popup in
            store.send(.mapMarkerTapped(popup))
        }
        NaverMapCoordinator.shared.onCenterChanged = { coordinate in
            store.send(.mapCenterChanged(coordinate))
        }

        LocationPermissionManager.shared.onPermissionDenied = {
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
        NaverMapCoordinator.shared.onCenterChanged = nil
        LocationPermissionManager.shared.onPermissionDenied = nil
        LocationPermissionManager.shared.onLocationUpdated = nil
    }

    func moveCamera(to popup: Popup, markerIndex: Int) {
        if firstSheetDetent == nil {
            NaverMapCoordinator.shared.moveCamera(to: popup)
        } else {
            NaverMapCoordinator.shared.moveCamera(to: popup, yOffset: -300)
        }

        NaverMapCoordinator.shared.focusMarker(identifier: markerIndex)
    }

    func updateSearchBarFrame(_ frame: CGRect) {
        DispatchQueue.main.async {
            if abs(searchBarFrame.maxY - frame.maxY) > 0.5 {
                searchBarFrame = frame
            }
        }
    }

    /// 두 번째 시트를 첫 번째 시트와 같은 높이로 연다. 첫 번째 시트가 숨어 있으면 중간 높이로 함께 꺼낸다.
    func openSecondSheet(_ sheet: MapSecondSheet) {
        let detent = firstSheetDetent ?? .medium
        firstSheetDetent = detent
        secondSheetDetent = detent
        secondSheet = sheet
    }
}

/// 내 위치 버튼. 시트 위쪽 끝을 따라 움직이고, 시트를 숨기면 목록 보기 버튼 오른쪽에 멈춘다.
/// 시트를 끝까지 올리면 흐려지며 숨는다.
/// 시트 높이는 끄는 동안 프레임마다 바뀌므로, 화면 body가 아니라 이 뷰에서 읽어 이 뷰만 다시 그려지게 한다.
/// 위치는 `offset`으로 옮긴다. 레이아웃 크기를 바꾸지 않아서 시트 높이가 화면 크기 계산으로 되돌아가지 않는다.
private struct MapLocationButtonLayer: View {
    /// 시트 위쪽 끝과 버튼 사이 간격.
    private static let spacing: CGFloat = 12
    /// 시트를 끝까지 올리기 전 이만큼 남았을 때부터 버튼이 흐려진다.
    private static let fadeDistance: CGFloat = 150

    let position: MapSheetPosition
    /// 시트를 숨겼을 때 버튼이 멈출 바닥 여백. 목록 보기 버튼과 같은 높이다.
    let restingBottomPadding: CGFloat
    let action: () -> Void

    var body: some View {
        let geometry = position.geometry
        let opacity = Self.opacity(for: geometry)

        Button(action: action) {
            DSKitResource.image("location")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
        .opacity(opacity)
        .allowsHitTesting(opacity > 0)
        .accessibilityHidden(opacity == 0)
        .padding(.trailing, 20)
        .offset(y: -max((geometry?.height ?? 0) + Self.spacing, restingBottomPadding))
    }

    /// 시트 높이를 받기 전에는 숨기고, 끝까지 올라가기 직전부터 흐려진다.
    private static func opacity(for geometry: BottomSheetGeometry?) -> CGFloat {
        guard let geometry else { return 0 }
        guard geometry.maxHeight > 0 else { return 1 }
        return min(max((geometry.maxHeight - geometry.height) / fadeDistance, 0), 1)
    }
}

private struct FirstSheetView: View {
    @Bindable var store: StoreOf<MapFeature>
    let onSortTap: () -> Void
    let onPopupTap: (Int, Popup) -> Void
    let onToggleLike: (Popup) -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()

                MapSortButton(selectedOption: store.selectedOption) {
                    onSortTap()
                }
            }
            .padding(.horizontal, .contentPadding)
            // 가까운순 줄을 끌어도 시트가 움직인다. 아래 목록은 목록만 스크롤한다.
            .bottomSheetDragHandle()

            MapListView(
                popups: store.mapPopups,
                isLoading: store.isLoading,
                isWaitingForUserLocation: store.isWaitingForUserLocation,
                onPopupTap: onPopupTap,
                onToggleLike: onToggleLike
            )
            .padding(.horizontal, .contentPadding)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

private struct MapListView: View {
    let popups: [Popup]
    let isLoading: Bool
    let isWaitingForUserLocation: Bool
    let onPopupTap: (Int, Popup) -> Void
    let onToggleLike: (Popup) -> Void

    var body: some View {
        if isWaitingForUserLocation {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        } else if isLoading && popups.isEmpty {
            ProgressView()
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        } else if popups.isEmpty {
            Text("검색 결과가 없습니다.", bundle: .module)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(Array(popups.enumerated()), id: \.element) { index, popup in
                        MapListPopupCell(
                            popup: popup,
                            onToggleLike: {
                                onToggleLike(popup)
                            }
                        )
                        .onTapGesture {
                            onPopupTap(index, popup)
                        }

                        if index != popups.count - 1 {
                            Divider()
                                .frame(height: 1)
                                .background(Color.subWhite)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 133)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
        }
    }
}

private struct SecondSheetView: View {
    @Bindable var store: StoreOf<MapFeature>
    let sheet: MapSecondSheet
    let onDismiss: () -> Void
    let onRegionSelected: (RegionList) -> Void
    let onDistrictSelected: (String) -> Void
    let onSortSelected: (MapSortOption) -> Void
    let onPopupDetailTap: (Popup) -> Void

    var body: some View {
        // 세 시트 모두 제목 줄로 시트를 끌고, 그 아래 내용은 스크롤만 한다.
        // 작은 화면의 가운데 높이에서는 내용이 다 들어가지 않으므로 목록이 아닌 내용도 스크롤로 둔다.
        Group {
            switch sheet {
            case .region:
                MapRegionSheet(
                    regions: store.regions,
                    selectedRegion: store.selectedRegion,
                    selectedDistrict: store.selectedDistrict,
                    onDismiss: onDismiss,
                    onRegionSelected: onRegionSelected,
                    onDistrictSelected: onDistrictSelected
                )

            case .sort:
                MapSortButtonSheet(
                    selectedOption: store.selectedOption,
                    onDismiss: onDismiss,
                    onSortSelected: onSortSelected
                )

            case .detail(let popup):
                DetailSheetView(
                    popup: popup,
                    onDismiss: onDismiss,
                    onDetailTap: {
                        onPopupDetailTap(popup)
                    }
                )
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}
