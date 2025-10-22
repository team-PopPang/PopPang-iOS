//
//  MapView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

/*
import SwiftUI
import NMapsMap
import Kingfisher
import BottomSheet

struct MapView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @StateObject private var mapViewModel = MapViewModel()
    @State var bottomSheetPosition: BottomSheetPosition = .relative(0.4)
    
    var body: some View {
        ZStack {
            NaverMapView(popups: mapViewModel.mapPopups) { popup in
                coordinator.push(.popupDetail(popup))
            }
                .ignoresSafeArea(edges: .top)
        }
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

struct NaverMapView: UIViewRepresentable {
    class _Coordinator {
        var clusterer: NMCClusterer<ItemKey>?
    }
    
    func makeCoordinator() -> _Coordinator {
        _Coordinator()
    }
    
    var popups: [Popup]
    var onMarkSelected: ((Popup) -> Void)?
    
    
    
    func makeUIView(context: Context) -> some NMFNaverMapView {
        let mapView = NMFNaverMapView(frame: .zero)
        
        // 로고 위치 조정
        mapView.mapView.logoAlign = .leftBottom
        mapView.mapView.logoMargin = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 0)
        
        // 내 위치 버튼 활성화 + 위치 모드 설정
        mapView.showLocationButton = true
        mapView.mapView.positionMode = .direction
        
        // 위치 오버레이(내 위치)
        let locationOverlay = mapView.mapView.locationOverlay
        locationOverlay.hidden = false
        
        // 약간의 지연 후 카메라 이동
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let coord = locationOverlay.location
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeOut
            mapView.mapView.moveCamera(cameraUpdate)
        }
        
        // 클러스터 생성
        let builder = NMCBuilder<ItemKey>()
        let clusterUpdater = ClusterMarkerUpdater()
        let leafUpdater = LeafMarkerUpdater()
        leafUpdater.onTap = onMarkSelected
        
        builder.clusterMarkerUpdater = clusterUpdater
        builder.leafMarkerUpdater = leafUpdater
        builder.screenDistance = 30
        builder.minZoom = 4
        builder.maxZoom = 18
        
        
        let clusterer = builder.build()
        DispatchQueue.main.async {
            clusterer.mapView = mapView.mapView
            context.coordinator.clusterer = clusterer
        }
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        guard let clusterer = context.coordinator.clusterer else {
            print("❌ clusterer가 nil입니다")
            return
        }
        clusterer.clear()
        
        waitForValidSizeAndAdd(uiView, clusterer: clusterer, retryCount: 0)
    }
    
    private func retryAddPopups(_ uiView: UIViewType, clusterer: NMCClusterer<ItemKey>) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let width = uiView.bounds.width
            let height = uiView.bounds.height
            guard width > 0 && height > 0 else {
                print("❌ 여전히 mapView 사이즈가 0입니다. 클러스터 적용 중단")
                return
            }
            uiView.layoutIfNeeded()
            addPopupsToClusterer(popups, clusterer)
            print("✅ 재시도 후 클러스터 적용 완료")
        }
    }
    
    private func waitForValidSizeAndAdd(
        _ uiView: UIViewType,
        clusterer: NMCClusterer<ItemKey>,
        retryCount: Int
    ) {
        let width = uiView.bounds.width
        let height = uiView.bounds.height

        // ✅ 맵 사이즈가 잡히지 않았을 경우 일정 횟수까지 재시도
        guard width > 0 && height > 0 else {
            if retryCount < 10 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    print("⏳ mapView 사이즈 아직 0, 재시도 \(retryCount + 1)")
                    waitForValidSizeAndAdd(uiView, clusterer: clusterer, retryCount: retryCount + 1)
                }
            } else {
                print("❌ mapView 사이즈가 끝내 0입니다. 클러스터 적용 중단")
            }
            return
        }

        uiView.layoutIfNeeded()
        addPopupsToClusterer(popups, clusterer)
        print("✅ mapView 크기 확인 후 클러스터 적용 완료")
    }
    
    // Popup 데이터를 클러스터러에 등록하는 함수
    private func addPopupsToClusterer(_ popups: [Popup],
                                      _ clusterer: NMCClusterer<ItemKey>
    ) {
        var keyTagMap: [ItemKey: NSObject] = [:]
        var validCount = 0

        for (index, popup) in popups.enumerated() {
            if let lat = popup.latitude, let lng = popup.longitude {
                let key = ItemKey(
                    identifier: index,
                    position: NMGLatLng(lat: lat, lng: lng),
                    popup: popup
                )
                keyTagMap[key] = popup.name as NSString
                validCount += 1
                print("✅ 마커 추가: \(popup.name) at (\(lat), \(lng))")
            } else {
                print("⚠️ 좌표 없음: \(popup.name)")
            }
        }
        if !keyTagMap.isEmpty {
            DispatchQueue.main.async {
                clusterer.addAll(keyTagMap)
                print("✅ 클러스터에 마커 추가 완료 (MainThread)")
            }
        }
        
        print("🧭 clusterer mapView:", clusterer.mapView as Any)
        print("🧭 clusterer key count:", keyTagMap.count)
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
*/

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
    
    var body: some View {
        ZStack {
            NaverMapView(popups: mapViewModel.mapPopups) { popup in
                coordinator.push(.popupDetail(popup))
            }
                .ignoresSafeArea(edges: .top)
        }
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

struct NaverMapView: UIViewRepresentable {
    var popups: [Popup]
    var onMarkSelected: ((Popup) -> Void)?
    
    func makeCoordinator() {}
    
    func makeUIView(context: Context) -> some NMFNaverMapView {
        let mapView = NMFNaverMapView(frame: .zero)
        
        // 로고 위치 조정
        mapView.mapView.logoAlign = .leftBottom
        mapView.mapView.logoMargin = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 0)
        
        // 내 위치 버튼 활성화 + 위치 모드 설정
        mapView.showLocationButton = true
        mapView.mapView.positionMode = .direction
        
        // 위치 오버레이(내 위치)
        let locationOverlay = mapView.mapView.locationOverlay
        locationOverlay.hidden = false
        
        // 약간의 지연 후 카메라 이동
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let coord = locationOverlay.location
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeOut
            mapView.mapView.moveCamera(cameraUpdate)
        }
        
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // 추후에 개수 변경시만 업데이트
        guard !popups.isEmpty else { return }
        
        // 위경도가 nil이 아닌 것만
        let validPopups = popups.filter { $0.latitude != nil && $0.longitude != nil }
        for popup in validPopups {
            
            guard let imageURL = URL(string: popup.imageUrlList[0]) else { continue }
            
            Task {
                if let roundedImage = await makeRoundedMarkerImage(from: imageURL) {
                    addCustomMarker(to: uiView.mapView, image: roundedImage, popup: popup)
                }
            }
        }
    }
    
    /// URL로부터 이미지를 불러와 둥근 사각형 UIImage로 변환
    func makeRoundedMarkerImage(from url: URL, size: CGSize = CGSize(width: 50, height: 50)) async -> UIImage? {
        do {
            let result = try await KingfisherManager.shared.retrieveImage(with: url)
            let originalImage = result.image
            let renderer = UIGraphicsImageRenderer(size: size)
            let roundedImage = renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
                path.addClip()
                originalImage.draw(in: rect)
            }
            return roundedImage
        } catch {
            return nil
        }
    }

    /// Naver Map에 마커 추가
    func addCustomMarker(to mapView: NMFMapView, image: UIImage, popup: Popup) {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: popup.latitude!, lng: popup.longitude!)
        marker.iconImage = NMFOverlayImage(image: image)
        marker.width = 50
        marker.height = 50
        marker.captionText = ""
        marker.userInfo = ["popup": popup]
        marker.mapView = mapView
        
        // ✅ 마커 클릭 시 동작
        marker.touchHandler = { overlay in
            if let marker = overlay as? NMFMarker,
               let selectedPopup = marker.userInfo["popup"] as? Popup {
                onMarkSelected?(selectedPopup)
            }
            return true
        }
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


