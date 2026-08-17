import NMapsMap
import SwiftUI

/// 네이버 지도 데모와 카메라 중심 좌표 오버레이를 함께 표시하는 루트 화면입니다.
struct NaverMapDemoRootView: View {
    /// 마지막으로 카메라 이동이 완료된 지도 중심 좌표입니다.
    @State private var cameraCenter = MapCameraCenter.seoulCityHall

    /// 네이버 지도 키 설정 여부에 따라 지도 또는 설정 안내 화면을 표시합니다.
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

    /// Coordinator에서 전달받은 카메라 중심 좌표를 표시하는 읽기 전용 오버레이입니다.
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

/// `NMFNaverMapView`의 카메라 이벤트를 SwiftUI 상태로 연결하는 UIKit 래퍼입니다.
private struct NaverMapDemoView: UIViewRepresentable {
    /// 카메라 이동이 완료된 뒤 새 중심 좌표를 상위 SwiftUI 화면으로 전달합니다.
    let onCameraCenterChanged: (MapCameraCenter) -> Void

    /// 네이버 지도 delegate 이벤트를 처리할 Coordinator를 생성합니다.
    func makeCoordinator() -> Coordinator {
        Coordinator(onCameraCenterChanged: onCameraCenterChanged)
    }

    /// 네이버 지도 UIKit 뷰를 생성하고 고정 옵션과 카메라 delegate를 최초 설정합니다.
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

    /// SwiftUI가 갱신될 때 Coordinator가 최신 중심 좌표 callback을 사용하도록 동기화합니다.
    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        context.coordinator.onCameraCenterChanged = onCameraCenterChanged
    }

    /// Representable이 제거될 때 등록했던 카메라 delegate를 해제합니다.
    static func dismantleUIView(_ uiView: NMFNaverMapView, coordinator: Coordinator) {
        uiView.mapView.removeCameraDelegate(delegate: coordinator)
    }

    /// 네이버 지도 카메라 delegate 이벤트를 SwiftUI callback으로 변환합니다.
    final class Coordinator: NSObject, NMFMapViewCameraDelegate {
        /// 상위 SwiftUI 화면이 제공한 최신 중심 좌표 수신 callback입니다.
        var onCameraCenterChanged: (MapCameraCenter) -> Void

        /// 중심 좌표 callback을 보관하는 Coordinator를 초기화합니다.
        init(onCameraCenterChanged: @escaping (MapCameraCenter) -> Void) {
            self.onCameraCenterChanged = onCameraCenterChanged
        }

        /// 카메라의 연속 이동과 애니메이션이 끝났을 때 최종 중심 좌표를 전달합니다.
        func mapViewCameraIdle(_ mapView: NMFMapView) {
            let target = mapView.cameraPosition.target
            let center = MapCameraCenter(latitude: target.lat, longitude: target.lng)

            DispatchQueue.main.async { [weak self] in
                self?.onCameraCenterChanged(center)
            }
        }
    }
}

/// 네이버 지도 중심 좌표를 SwiftUI에서 비교하고 표시하기 위한 값 타입입니다.
private struct MapCameraCenter: Equatable {
    /// 중심점의 위도입니다.
    let latitude: Double

    /// 중심점의 경도입니다.
    let longitude: Double

    /// 데모 지도가 처음 표시할 서울시청 좌표입니다.
    static let seoulCityHall = MapCameraCenter(
        latitude: 37.5665,
        longitude: 126.9780
    )
}
