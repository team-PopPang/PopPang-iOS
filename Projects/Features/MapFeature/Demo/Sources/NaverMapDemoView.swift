import NMapsMap
import SwiftUI

struct NaverMapDemoRootView: View {
    var body: some View {
        Group {
            if MapFeatureDemoConfiguration.naverMapClientID == nil {
                ContentUnavailableView(
                    "네이버 지도 키가 필요합니다",
                    systemImage: "key.horizontal",
                    description: Text(
                        "Projects/App/Secrets.xcconfig에 NMFClientID를 설정한 뒤 다시 실행해 주세요."
                    )
                )
            } else {
                NaverMapDemoView()
                    .ignoresSafeArea()
            }
        }
    }
}

private struct NaverMapDemoView: UIViewRepresentable {
    func makeUIView(context: Context) -> NMFNaverMapView {
        let naverMapView = NMFNaverMapView(frame: .zero)
        let mapView = naverMapView.mapView

        mapView.zoomLevel = 15
        mapView.minZoomLevel = 5
        mapView.maxZoomLevel = 20
        mapView.isNightModeEnabled = false
        mapView.logoAlign = .leftBottom
        mapView.logoMargin = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 0)

        naverMapView.showCompass = true
        naverMapView.showLocationButton = false
        naverMapView.showScaleBar = false
        naverMapView.showZoomControls = false

        let seoulCityHall = NMGLatLng(lat: 37.5665, lng: 126.9780)
        mapView.moveCamera(NMFCameraUpdate(scrollTo: seoulCityHall))

        return naverMapView
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {}
}
