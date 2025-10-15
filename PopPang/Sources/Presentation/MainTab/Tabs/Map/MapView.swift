//
//  MapView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import NMapsMap
import Kingfisher

struct MapView: View {
    @StateObject private var mapViewModel = MapViewModel()
    var body: some View {
        ZStack {
            NaverMapView(popups: mapViewModel.mapPopups)
                .ignoresSafeArea(edges: .top)
                
            /*
            VStack {
                Spacer()
                RoundedCorner(radius: 20, corners: [.topLeft, .topRight])
                    .fill(Color.subWhite)
                    .frame(maxWidth: .infinity)
                    .frame(height: 300)
            }
             */
        }
        .onAppear {
            LocationPermissionManager.shared.requestPermission()
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
            print("❌ Kingfisher 이미지 로드 실패:", error)
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

#Preview {
    MapView()
}


import CoreLocation

class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()
    private override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // 위치권한 및 상태 관리 클래스
    // 권한 요청, 권한 상태감지, 위치 업데이트 가능
    private let locationManager = CLLocationManager()
    
    // 권한 요청
    func requestPermission() {
        // ✅ 권한 요청
        locationManager.requestWhenInUseAuthorization()
        // 만약 백그라운드까지 필요하다면:
        // locationManager.requestAlwaysAuthorization()
    }
    
    // 권한 변경 감지
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 허용됨")
        case .denied, .restricted:
            print("❌ 위치 권한 거부됨")
        case .notDetermined:
            print("🕒 아직 권한 선택 전")
        @unknown default:
            break
        }
    }
}
