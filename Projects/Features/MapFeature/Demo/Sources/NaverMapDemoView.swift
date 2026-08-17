import NMapsMap
import SwiftUI

struct NaverMapDemoRootView: View {
    @State private var cameraCenter = MapCameraCenter.seoulCityHall

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
                ZStack(alignment: .top) {
                    NaverMapDemoView { center in
                        cameraCenter = center
                    }
                    .ignoresSafeArea()

                    cameraCenterOverlay
                }
            }
        }
    }

    private var cameraCenterOverlay: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("카메라 중심")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(
                "위도 \(cameraCenter.latitude, format: .number.precision(.fractionLength(6)))  경도 \(cameraCenter.longitude, format: .number.precision(.fractionLength(6)))"
            )
            .font(.callout.monospacedDigit().weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.top, 12)
        .allowsHitTesting(false)
    }
}

private struct NaverMapDemoView: UIViewRepresentable {
    let onCameraCenterChanged: (MapCameraCenter) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onCameraCenterChanged: onCameraCenterChanged)
    }

    func makeUIView(context: Context) -> NMFNaverMapView {
        let naverMapView = NMFNaverMapView(frame: .zero)
        let mapView = naverMapView.mapView

        mapView.zoomLevel = 15
        mapView.minZoomLevel = 5
        mapView.maxZoomLevel = 20
        mapView.isNightModeEnabled = false
        mapView.logoAlign = .leftBottom
        mapView.logoMargin = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 0)
        mapView.addCameraDelegate(delegate: context.coordinator)

        naverMapView.showCompass = true
        naverMapView.showLocationButton = false
        naverMapView.showScaleBar = false
        naverMapView.showZoomControls = false

        let seoulCityHall = NMGLatLng(
            lat: MapCameraCenter.seoulCityHall.latitude,
            lng: MapCameraCenter.seoulCityHall.longitude
        )
        mapView.moveCamera(NMFCameraUpdate(scrollTo: seoulCityHall))

        return naverMapView
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        context.coordinator.onCameraCenterChanged = onCameraCenterChanged
    }

    static func dismantleUIView(_ uiView: NMFNaverMapView, coordinator: Coordinator) {
        uiView.mapView.removeCameraDelegate(delegate: coordinator)
    }

    final class Coordinator: NSObject, NMFMapViewCameraDelegate {
        var onCameraCenterChanged: (MapCameraCenter) -> Void

        init(onCameraCenterChanged: @escaping (MapCameraCenter) -> Void) {
            self.onCameraCenterChanged = onCameraCenterChanged
        }

        func mapViewCameraIdle(_ mapView: NMFMapView) {
            let target = mapView.cameraPosition.target
            let center = MapCameraCenter(latitude: target.lat, longitude: target.lng)

            DispatchQueue.main.async { [weak self] in
                self?.onCameraCenterChanged(center)
            }
        }
    }
}

private struct MapCameraCenter: Equatable {
    let latitude: Double
    let longitude: Double

    static let seoulCityHall = MapCameraCenter(
        latitude: 37.5665,
        longitude: 126.9780
    )
}
