//
//  MapView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import NMapsMap

struct MapView: View {
    @StateObject private var mapViewModel = MapViewModel()
    var body: some View {
        NaverMapView(popups: mapViewModel.mapPopups)
            .ignoresSafeArea(edges: .top)
    }
}

final class MapViewModel: ObservableObject {
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var mapPopups: [Popup] = []
    
    init() {
        Task {
            do {
                let popups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.mapPopups = popups
                }
            } catch {
                print("❌ MapViewModel getPopupList Error: \(error)")
            }
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
            guard let latRaw = popup.latitude, let lngRaw = popup.longitude else {
                print("⚠️ 좌표 없음 → \(popup.name)")
                continue
            }
            
            // ⚠️ 현재 데이터는 10배 커져 있으므로 변환
            let lat = latRaw
            let lng = lngRaw
            
            print("좌표 있음 -> \(popup.name), \(popup.latitude!), \(popup.longitude!)")
            let marker = NMFMarker()
            marker.position = NMGLatLng(lat: lat, lng: lng)
            marker.iconImage = NMF_MARKER_IMAGE_BLACK // 🟤 기본 검은 동그라미
            marker.width = 30   // 기본보다 크게
            marker.height = 30  // 정사각형으로 동그라미 느낌
            marker.captionText = popup.name
            marker.captionTextSize = 14
            marker.captionColor = .black
            marker.mapView = uiView.mapView
        }
    }
}

#Preview {
    MapView()
}

