//
//  MapView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import NMapsMap
import Kingfisher
import BottomSheet

struct MapView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @StateObject private var mapViewModel = MapViewModel()
    @State var bottomSheetPosition: BottomSheetPosition = .relative(0.4)
    @State private var text = ""
    
    var body: some View {
        ZStack(alignment: .trailing) {
            NaverMapView(popups: mapViewModel.mapPopups)
                .onAppear {
                    MapCoordinator.shared.checkIfLocationServiceIsEnabled()
                    MapCoordinator.shared.onMarkerSelected = { key, popup in
                        coordinator.push(.popupDetail(popup))
                    }
                }

            
            MapSearchTextField(placeholder: "궁금한 팝업을 검색해보세요",
                               text: $text)
            .frame(maxHeight: .infinity, alignment: .top)
            .padding(.top, 70)
            .padding(.horizontal, 15)
            
            Button {
                MapCoordinator.shared.moveToUserLocation()
            } label: {
                Image(systemName: "location.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.blue)
                    .padding()
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(radius: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 50)
        }
        .ignoresSafeArea(edges: .top)
        .onAppear {
            LocationPermissionManager.shared.requestPermission()
        }
        .bottomSheet(bottomSheetPosition: self.$bottomSheetPosition,
                     switchablePositions: [.absolute(120), .relative(0.4), .relative(0.6), .relative(0.95)],
                     content: {
            
            MapListView(popups: mapViewModel.mapPopups)
                .padding(.horizontal, .contentPadding)
        })
        .customBackground(
            Color.subWhite
                .cornerRadius(30)
        )
    }
}

// MARK: - SwiftUI와 UIKit 연결
struct NaverMapView: UIViewRepresentable {
    var popups: [Popup]
    func makeCoordinator() -> MapCoordinator {
        Coordinator.shared
    }

    func makeUIView(context: Context) -> some UIView {
        context.coordinator.getNaverMapView()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // vm에서 spots갱신시마다 Coordinator에 반영
        context.coordinator.updateSpots(popups)
    }
}

final class MapCoordinator: NSObject,
                            ObservableObject,
                            CLLocationManagerDelegate,
                            NMFMapViewCameraDelegate {
    
    static let shared = MapCoordinator()
    let view = NMFNaverMapView(frame: .zero)
    var locationManager: CLLocationManager?
    var popups: [Popup] = []
    var clusterer: NMCClusterer<ItemKey>?
    var onMarkerSelected: ((ItemKey, Popup) -> Void)?

    override init() {
        super.init()
        setupMap()

        // ✅ 마커 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.makeClusterer()
            self.moveToUserLocation()
        }
    }

    // MARK: - 지도 기본 설정
    /// 지도 초기 상태를 설정합니다.
    /// - 줌 레벨, 최소/최대 줌, 모드(positionMode), 초기 카메라 위치 등을 지정
    private func setupMap() {
        view.mapView.addCameraDelegate(delegate: self)
        
        view.mapView.zoomLevel = 10
        view.mapView.minZoomLevel = 5
        view.mapView.maxZoomLevel = 20
        view.mapView.positionMode = .direction
        
        view.mapView.isNightModeEnabled = false
        view.showLocationButton = false           // 디폴트 내위치 이동 버튼 비활성화
        view.showZoomControls = false             // 줌 확대, 축소 버튼 비활성화
        view.showCompass = true                   // 지도 회전시 나침반 활성화
        view.showScaleBar = false                 // 우측 하단 축적바 비활성화
        
        // 로고 위치 조정
        view.mapView.logoAlign = .leftBottom
        view.mapView.logoMargin = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 0)

        // 서울 시청 기준
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: 37.5665, lng: 126.9780))
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }

    // MARK: - 지도 반환
    /// UIViewRepresentable에서 실제 네이버 지도를 가져갈 수 있도록 반환
    func getNaverMapView() -> NMFNaverMapView {
        return view
    }
    
    
    // MARK: - 위치 권한 요청
    /// 위치 서비스가 켜져 있는지 확인 후,
    /// CLLocationManager를 초기화하여 위치 추적을 시작할 수 있도록 준비
    func checkIfLocationServiceIsEnabled() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    self.locationManager = CLLocationManager()
                    self.locationManager!.delegate = self
                    self.locationManager!.desiredAccuracy = kCLLocationAccuracyBest  // 정확도 향상
                }
            } else {
                print("⚠️ 위치 서비스가 꺼져 있습니다.")
            }
        }
    }
    
    // MARK: - 사용자 위치로 이동
    /// 현재 사용자의 위치로 카메라를 이동
    /// 위치 오버레이의 좌표를 기반으로 이동
    func moveToUserLocation() {
        let coord = view.mapView.locationOverlay.location
        let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }
}

// MARK: - 클러스터 관련
extension MapCoordinator {
    
    // MARK: 클러스터 생성
    /// 지도 위의 Spot 배열을 기반으로 클러스터를 생성합니다.
    /// - minZoom: 멀리서도 묶임이 시작되는 줌 레벨
    /// - maxZoom: 이 줌 이상에서는 클러스터가 풀리고 개별 마커로 전환됨
    /// - screenDistance: 마커가 얼마나 가까이 있을 때 클러스터로 묶일지 (픽셀 단위)
    private func makeClusterer() {
        
        // 기존 클러스터 제거
        self.clusterer?.clear()
        self.clusterer = nil
        
        let builder = NMCBuilder<ItemKey>()
        
        // 커스텀 리프 마커 등록 (사각형이나 파란색 심볼 등)
        let leafUpdater = LeafMarkerUpdater()
        leafUpdater.onMarkerSelected = { [weak self] key in
            guard let self = self else { return }
            if key.identifier < self.popups.count {
                let selectedPopup = self.popups[key.identifier]
                self.onMarkerSelected?(key, selectedPopup)
            }
        }
        builder.leafMarkerUpdater = leafUpdater
        
        // 클러스터 마커도 필요하면 등록
        let clusterUpdater = ClusterMarkerUpdater()
        builder.clusterMarkerUpdater = clusterUpdater
        
        // 클러스터 동작 범위
        // builder.minZoom = 10            // 멀리서도 묶임 시작(필요시 조정)
        // builder.maxZoom = 12           // 이 줌 이상이면 바로 분리(값 낮출수록 빨리 풀림)
        // builder.screenDistance = 40.0  // 마커 간 거리 기준(px). 작을수록 빨리 분리됨
        
        builder.minZoom = 5           // 전국 축소에도 클러스터 작동
        builder.maxZoom = 12          // 완전히 확대하면 분리
        
        self.clusterer = builder.build()
        
        // Spot을 ItemKey로 변환하여 클러스터에 추가
        var keyTagMap: [ItemKey: NSObject] = [:]
        for (index, popup) in popups.enumerated() {
            let key = ItemKey(identifier: index,
                              position: NMGLatLng(lat: popup.latitude ?? 0, lng: popup.longitude ?? 0), imageURL: popup.imageUrlList[0])
            keyTagMap[key] = NSNull()
        }
        clusterer?.addAll(keyTagMap)
        clusterer?.mapView = self.view.mapView
    }
    
    
    // MARK: Spot 데이터 갱신
    /// ViewModel에서 Spot 배열이 변경될 때마다 호출됨
    /// 새로운 Spot 데이터로 클러스터를 다시 생성
    func updateSpots(_ newPopups: [Popup]) {
        self.popups = newPopups
        makeClusterer()
    }
}

extension MapCoordinator {
    func mapViewCameraIdle(_ mapView: NMFMapView) {
        let zoom = mapView.zoomLevel
        print("📸 현재 줌 레벨: \(zoom)")
    }
}

#Preview("지도 탭 미리보기") {
    @Previewable @State var selectedTab: MainTabType = .map
    TabView(selection: .constant(MainTabType.map)) {
        MapView()
            .tabItem {
                Image(systemName: "map")
                Text("지도")
            }
            .tag(MainTabType.map)
    }
    .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
}
