import BottomSheet
import ComposableArchitecture
import Domain
import DSKit
import SwiftUI
import UIKit

public struct MapFeatureView: View {
    @Bindable var store: StoreOf<MapFeature>
    @State private var tabBarHeight: CGFloat = 0
    @State private var searchBarFrame: CGRect = .zero
    @State private var sheetTop: CGFloat = 400
    @State private var showLocationPermissionAlert = false

    public init(store: StoreOf<MapFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { _ in
            ZStack {
                ZStack(alignment: .trailing) {
                    NaverMapView(popups: store.mapPopups)
                        .ignoresSafeArea()

                    topControls
                        .frame(maxHeight: .infinity, alignment: .top)
                        .padding(.top, safeAreaInsets.top + 10)
                        .padding(.horizontal, 15)

                    currentLocationButton
                        .padding(.trailing, 20)
                        .padding(.bottom, 50)

                    if isFirstSheetHidden(store.firstSheetPosition) {
                        listButton
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .padding(.bottom, 20 + tabBarHeight)
                    }
                }
                .background {
                    TabBarProxy { _, tabBar in
                        tabBarHeight = tabBar.bounds.height
                    }
                }
                .alert("위치 권한이 필요합니다", isPresented: $showLocationPermissionAlert) {
                    Button("설정으로 이동") {
                        guard let url = URL(string: UIApplication.openSettingsURLString),
                              UIApplication.shared.canOpenURL(url)
                        else { return }
                        UIApplication.shared.open(url)
                    }
                    Button("취소", role: .cancel) {}
                } message: {
                    Text("주변 팝업스토어를 지도에서 보여주고 내 위치로 이동하려면 위치 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.")
                }
                .bottomSheet(
                    bottomSheetPosition: firstSheetPositionBinding,
                    switchablePositions: [
                        .absolute(0),
                        .relative(0.5),
                        .absoluteTop(sheetTop),
                    ],
                    content: {
                        FirstSheetView(
                            store: store,
                            onSortTap: {
                                store.send(.sortButtonTapped)
                            },
                            onPopupTap: { index, popup in
                                moveCamera(to: popup, markerIndex: index)
                                store.send(.popupPreviewRequested(popup))
                            },
                            onToggleLike: { popup in
                                store.send(.toggleLike(popup))
                            }
                        )
                    }
                )
                .sheetWidth(.relative(1.0))
                .customBackground(
                    Color.subWhite
                        .cornerRadius(30)
                )

                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .bottomSheet(
                        bottomSheetPosition: secondSheetPositionBinding,
                        switchablePositions: [
                            .relative(0.5),
                            .absoluteTop(sheetTop),
                        ],
                        content: {
                            SecondSheetView(
                                store: store,
                                onDismiss: {
                                    store.send(.dismissSecondSheet)
                                },
                                onRegionSelected: { region in
                                    store.send(.regionSelected(region))
                                },
                                onDistrictSelected: { district in
                                    store.send(.districtSelected(district))
                                },
                                onSortSelected: { option in
                                    store.send(.sortOptionSelected(option))
                                },
                                onPopupDetailTap: { popup in
                                    store.send(.popupDetailTapped(popup))
                                }
                            )
                        }
                    )
                    .sheetWidth(.relative(1.0))
                    .customBackground(
                        Color.subWhite
                            .cornerRadius(30)
                    )
                    .allowsHitTesting(store.secondSheetPosition != .hidden)
                    .zIndex(1)
            }
            .onAppear {
                configureCallbacks()
                store.send(.onAppear)
            }
            .onDisappear {
                clearCallbacks()
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
                    store.send(.regionButtonTapped)
                }

                Divider()
                    .frame(width: 1, height: 20)
                    .background(Color.mainGray8)

                MapSearchTextField(
                    placeholder: "궁금한 팝업을 검색해보세요",
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

    var currentLocationButton: some View {
        Button {
            if isFirstSheetHidden(store.firstSheetPosition) {
                NaverMapCoordinator.shared.moveToUserLocation()
            } else {
                NaverMapCoordinator.shared.moveToUserLocation(yOffset: -300)
            }
        } label: {
            DSKitResource.image("location")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 4)
        }
        .buttonStyle(.plain)
    }

    var listButton: some View {
        Button {
            store.send(.listButtonTapped)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "list.bullet")
                    .foregroundStyle(Color.mainBlack)
                    .frame(width: 12, height: 12)
                    .padding(.bottom, 3)

                Text("목록 보기")
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

    var firstSheetPositionBinding: Binding<BottomSheetPosition> {
        Binding(
            get: { store.firstSheetPosition },
            set: { store.send(.firstSheetPositionChanged($0)) }
        )
    }

    var secondSheetPositionBinding: Binding<BottomSheetPosition> {
        Binding(
            get: { store.secondSheetPosition },
            set: { store.send(.secondSheetPositionChanged($0)) }
        )
    }

    var safeAreaInsets: UIEdgeInsets {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
            let window = scene.windows.first(where: { $0.isKeyWindow })
        else {
            return .zero
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
        if isFirstSheetHidden(store.firstSheetPosition) {
            NaverMapCoordinator.shared.moveCamera(to: popup)
        } else {
            NaverMapCoordinator.shared.moveCamera(to: popup, yOffset: -300)
        }

        NaverMapCoordinator.shared.focusMarker(identifier: markerIndex)
    }

    func updateSearchBarFrame(_ frame: CGRect) {
        DispatchQueue.main.async {
            searchBarFrame = frame
            let top = UIScreen.main.bounds.height - (frame.maxY + 20)
            let nextSheetTop = max(top, 200)
            if abs(sheetTop - nextSheetTop) > 0.5 {
                sheetTop = nextSheetTop
            }
        }
    }

    func isFirstSheetHidden(_ position: BottomSheetPosition) -> Bool {
        switch position {
        case .hidden:
            true
        case .absolute(let value):
            value == 0
        default:
            false
        }
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
            Text("검색 결과가 없습니다.")
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
    let onDismiss: () -> Void
    let onRegionSelected: (RegionList) -> Void
    let onDistrictSelected: (String) -> Void
    let onSortSelected: (MapSortOption) -> Void
    let onPopupDetailTap: (Popup) -> Void

    var body: some View {
        ScrollView {
            switch store.secondSheetType {
            case .region:
                MapRegionSheet(
                    regions: store.regions,
                    selectedRegion: store.selectedRegion,
                    selectedDistrict: store.selectedDistrict,
                    onDismiss: onDismiss,
                    onRegionSelected: onRegionSelected,
                    onDistrictSelected: onDistrictSelected
                )
                .padding(.bottom, 100)

            case .sort:
                MapSortButtonSheet(
                    selectedOption: store.selectedOption,
                    onDismiss: onDismiss,
                    onSortSelected: onSortSelected
                )
                .padding(.bottom, 100)

            case .detail(let popup):
                DetailSheetView(
                    popup: popup,
                    onDismiss: onDismiss,
                    onDetailTap: {
                        onPopupDetailTap(popup)
                    }
                )

            case .none:
                EmptyView()
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}
