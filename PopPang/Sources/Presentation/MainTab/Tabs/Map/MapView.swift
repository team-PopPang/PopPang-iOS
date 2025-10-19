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

struct MapView: View {
    @StateObject private var mapViewModel = MapViewModel()
    @State private var showSheet: Bool = true
    var body: some View {
        ZStack {
            NaverMapView(popups: mapViewModel.mapPopups)
                .ignoresSafeArea(edges: .top)
                
        }
        .onAppear {
            LocationPermissionManager.shared.requestPermission()
        }
        .sheet(isPresented: $showSheet) {
            MapListView(popups: mapViewModel.mapPopups)
                .padding(.contentPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .presentationDetents([.height(300), .medium, .large])
                .presentationCornerRadius(20) // ✅ 시스템 라운드
                // .presentationBackground(.regularMaterial)
                .presentationBackground(Color.subWhite)
                .presentationBackgroundInteraction(.enabled(upThrough: .large))
                .interactiveDismissDisabled()
                .mapSheet(49)
        }
    }
}

struct MapListView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    let popups: [Popup]
    
    var body: some View {
        if popups.isEmpty {
            Text("팝업 데이터 수집중")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(popups.enumerated()), id: \.element) { index, popup in
                        MapListPopupCell(popup: popup)
                            .onTapGesture {
                                coordinator.push(.popupDetail(popup))
                            }
                        
                        // 마미막 셀 아래에는 Divider 넣지 않겠다
                        if index != popups.count - 1 {
                            Divider()
                                .frame(height: 1)
                                .background(Color.subWhite)
                        }
                    }
                }
            }
            .padding(.top, 20)
        }
    }
}

struct MapListPopupCell: View {
    let popup: Popup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                KFImage(URL(string: popup.imageURL))
                    .placeholder {
                        Rectangle()
                            .fill(Color.mainGray3)
                            .frame(width: 106, height: 133)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133, alignment: .center)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.roadAddress?.shortAddress ?? popup.address.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                    
                    Text(popup.name)
                        .font(.scdream(.bold, size: 15))
                        .foregroundStyle(Color.mainBlack)
                        .lineLimit(1) // 한줄만 표시
                        .truncationMode(.tail) // 넘치면 ...으로 표시
                        .padding(.top, 5)
                  
                    HStack {
                        Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                        Text("-")
                        Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                    }
                    .font(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainGray)
                    .padding(.top, 5)
                    .padding(.leading, -1)
                    
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct NaverMapView: UIViewRepresentable {
    var popups: [Popup]
    
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
        locationOverlay.hidden = false  // 내 위치 마커 표시
        
        // 약간의 지연 후 카메라 이동
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            let coord = locationOverlay.location
            let cameraUpdate = NMFCameraUpdate(scrollTo: coord)
            cameraUpdate.animation = .easeOut
            mapView.mapView.moveCamera(cameraUpdate)
        }
        
        // ✅ 기본 UI 컨트롤 비활성화
        /*
        mapView.showCompass = false
        mapView.showScaleBar = false
        mapView.showZoomControls = false
        mapView.showLocationButton = false
         */
        return mapView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        for popup in popups {
            guard let lat = popup.latitude, let lng = popup.longitude else {
                // print("⚠️ 좌표 없음 → \(popup.name)")
                continue
            }
            
            let imageURL = URL(string: popup.imageURL)!
            
            
            // MARK: - 마커1
            /*
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: lat, lng: lng)
            marker.iconImage = NMF_MARKER_IMAGE_BLACK // 🟤 기본 검은 동그라미
            marker.width = 30   // 기본보다 크게
            marker.height = 30  // 정사각형으로 동그라미 느낌
            marker.captionText = popup.name
            marker.captionTextSize = 14
            marker.captionColor = .black
            marker.mapView = uiView.mapView
             */
            
            // MARK: - 마커2
            Task {
                if let roundedImage = await makeRoundedMarkerImage(from: imageURL) {
                    addCustomMarker(to: uiView.mapView, image: roundedImage, lat: lat, lng: lng)
                }
            }
        }
    }
    
    /// URL로부터 이미지를 불러와 둥근 사각형 UIImage로 변환
    func makeRoundedMarkerImage(from url: URL, size: CGSize = CGSize(width: 50, height: 50)) async -> UIImage? {
        do {
            // ✅ Kingfisher로 비동기 이미지 다운로드 + 캐싱
            let result = try await KingfisherManager.shared.retrieveImage(with: url)
            let originalImage = result.image

            // ✅ 둥근 사각형 마스크 적용
            let renderer = UIGraphicsImageRenderer(size: size)
            let roundedImage = renderer.image { context in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
                path.addClip()
                originalImage.draw(in: rect)
            }

            return roundedImage
        } catch {
            // print("❌ Kingfisher 이미지 로드 실패:", error)
            return nil
        }
    }

    
    /// Naver Map에 마커 추가
    func addCustomMarker(to mapView: NMFMapView, image: UIImage, lat: Double, lng: Double) {
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: lat, lng: lng)
        marker.iconImage = NMFOverlayImage(image: image)
        marker.width = 50
        marker.height = 50
        marker.captionText = ""  // 텍스트를 따로 붙이고 싶으면 여기에 설정
        marker.mapView = mapView
    }
}

#Preview("지도 탭 미리보기") {
    TabView(selection: .constant(MainTabType.map)) {   // ✅ 프리뷰 전용 탭 뷰
        MapView()
            .tabItem {
                Image(systemName: "map")
                Text("지도")
            }
            .tag(MainTabType.map)
    }
}

//#Preview {
//    MapView()
//}
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

struct MapListView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    let popups: [Popup]
    
    var body: some View {
        if popups.isEmpty {
            Text("팝업 데이터 수집중")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(popups.enumerated()), id: \.element) { index, popup in
                        MapListPopupCell(popup: popup)
                            .onTapGesture {
                                coordinator.push(.popupDetail(popup)) // ✅ 디테일 화면 이동
                            }
                        
                        if index != popups.count - 1 {
                            Divider()
                                .frame(height: 1)
                                .background(Color.subWhite)
                        }
                    }
                }
            }
            .padding(.top, 20)
        }
    }
}

struct MapListPopupCell: View {
    let popup: Popup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                KFImage(URL(string: popup.imageURL))
                    .placeholder {
                        Rectangle()
                            .fill(Color.mainGray3)
                            .frame(width: 106, height: 133)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133, alignment: .center)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.roadAddress?.shortAddress ?? popup.address.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                    
                    Text(popup.name)
                        .font(.scdream(.bold, size: 15))
                        .foregroundStyle(Color.mainBlack)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.top, 5)
                  
                    HStack {
                        Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                        Text("-")
                        Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                    }
                    .font(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainGray)
                    .padding(.top, 5)
                    .padding(.leading, -1)
                    
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
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
            
            guard let imageURL = URL(string: popup.imageURL) else { continue }
            
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

