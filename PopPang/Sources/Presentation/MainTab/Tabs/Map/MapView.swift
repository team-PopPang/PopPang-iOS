//
//  MapView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import NMapsMap

struct MapView: View {
    var body: some View {
        NaverMapView()
            .ignoresSafeArea(edges: .top)
    }
}


struct NaverMapView: UIViewRepresentable {
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
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

#Preview {
    MapView()
}

