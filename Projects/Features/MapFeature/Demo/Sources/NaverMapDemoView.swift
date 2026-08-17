import CoreLocation
import NMapsMap
import SwiftUI
import UIKit

/**
 // 1. SwiftUI가 현재 callback을 NaverMapDemoView에 전달
 NaverMapDemoView { center in
     cameraCenter = center
 }

 // 2. 처음 생성 시, 그 callback을 Coordinator에 전달
 Coordinator(onCameraCenterChanged: onCameraCenterChanged)

 // 3. 지도 이벤트가 나중에 발생하면 Coordinator가 저장한 callback 실행
 func mapViewCameraIdle(_ mapView: NMFMapView) {
     onCameraCenterChanged(center)
 }

 Coordinator는 NaverMapDemoView보다 오래 살아남을 수 있습니다. SwiftUI는 상태가 바뀔 때 NaverMapDemoView 구조체를 새 값으로 만들지만, 기존 UIKit 지도와 Coordinator는 재사용합니다.

 그래서 [updateUIView (line 91)](/Users/kimdonghyeon/2025/develop/App/PopPang/PopPang/Projects/Features/MapFeature/Demo/Sources/NaverMapDemoView.swift:91)에서 Coordinator의 callback을 최신 값으로 교체합니다.

 NaverMapDemoView의 callback: SwiftUI가 전달한 최신 입력값
 Coordinator의 callback: UIKit delegate가 실제 이벤트 시점에 실행할 저장값

 SwiftUI 상태만 UIKit에 반영한다
 → Representable 프로퍼티 + updateUIView

 UIKit 이벤트를 SwiftUI에 전달한다
 → Representable 프로퍼티 + Coordinator 프로퍼티 + delegate

 UIKit 객체를 계속 보관해야 한다
 → Coordinator 프로퍼티



 1. UIKit 이벤트가 없다, SwiftUI 값만 지도에 적용
    → Coordinator 없음
    예: 줌 레벨, 지도 스타일만 SwiftUI에서 설정

 2. UIKit 이벤트가 있지만 SwiftUI에 알릴 필요가 없다
    → Coordinator는 필요할 수 있지만 callback 프로퍼티는 없음
    예: Coordinator 내부에서 마커 캐시만 관리

 3. UIKit 이벤트를 SwiftUI 상태에 전달해야 한다
    → NaverMapDemoView와 Coordinator 둘 다 callback 프로퍼티 필요
    예: 현재 카메라 중심 좌표 전달

 4. SwiftUI가 다시 렌더링될 때 callback이 바뀔 수 있다
    → updateUIView에서 Coordinator의 callback 갱신 필요
    예: 현재 onCameraCenterChanged

 // 우리 앱 일반 설정
 openURL(URL(string: UIApplication.openSettingsURLString)!)

 // 우리 앱 알림 설정
 openURL(URL(string: UIApplication.openNotificationSettingsURLString)!)
 */

/// 네이버 지도 데모와 카메라 중심 좌표 오버레이를 함께 표시하는 루트 화면입니다.
struct NaverMapDemoRootView: View {
    @Environment(\.openURL) private var openURL

    /// 마지막으로 카메라 이동이 완료된 지도 중심 좌표입니다.
    @State private var cameraCenter = MapCameraCenter.seoulCityHall
    @State private var locationRequestID: UUID?
    @State private var locationFailure: LocationFailure?

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
                ZStack {
                    NaverMapDemoView(
                        locationRequestID: locationRequestID,
                        onCameraCenterChanged: { center in
                            cameraCenter = center
                        },
                        onLocationError: { failure in
                            locationFailure = failure
                        }
                    )
                    .ignoresSafeArea()

                    cameraCenterOverlay
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                    currentLocationButton
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                }
                .alert(
                    locationFailure?.title ?? "현재 위치를 가져올 수 없습니다",
                    isPresented: Binding(
                        get: { locationFailure != nil },
                        set: { isPresented in
                            if isPresented == false {
                                locationFailure = nil
                            }
                        }
                    )
                ) {
                    if locationFailure?.requiresSettings == true {
                        Button("설정으로 이동") {
                            openAppSettings()
                        }
                    }

                    Button("확인", role: .cancel) {
                        locationFailure = nil
                    }
                } message: {
                    Text(locationFailure?.message ?? "")
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

    /// 새 위치 요청 토큰을 만들어 Coordinator에 현재 위치 이동을 요청하는 버튼입니다.
    private var currentLocationButton: some View {
        Button {
            locationRequestID = UUID()
        } label: {
            Image(systemName: "location.fill")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(14)
                .background(.regularMaterial, in: Circle())
        }
        .padding(.trailing, 20)
        .padding(.bottom, 40)
        .accessibilityLabel("내 위치로 이동")
    }

    /// 앱 설정 화면을 열어 사용자가 위치 권한을 직접 변경할 수 있게 합니다.
    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }

        openURL(settingsURL)
    }
}

/// `NMFNaverMapView`의 카메라 이벤트를 SwiftUI 상태로 연결하는 UIKit 래퍼입니다.
private struct NaverMapDemoView: UIViewRepresentable {
    /// SwiftUI 버튼 탭마다 새로 전달되는 현재 위치 이동 요청 식별자입니다.
    let locationRequestID: UUID?
    /// 카메라 이동이 완료된 뒤 새 중심 좌표를 상위 SwiftUI 화면으로 전달합니다.
    let onCameraCenterChanged: (MapCameraCenter) -> Void

    /// 위치 권한 거부 또는 현재 위치 조회 실패 상태를 상위 화면으로 전달합니다.
    let onLocationError: (LocationFailure) -> Void

    /// UIViewRepresentable 메서드 - 네이버 지도 delegate 이벤트를 처리할 Coordinator를 생성합니다.
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onCameraCenterChanged: onCameraCenterChanged,
            onLocationError: onLocationError
        )
    }

    /// UIViewRepresentable 메서드 - 네이버 지도 UIKit 뷰를 생성하고 고정 옵션과 카메라 delegate를 최초 설정합니다.
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

    /// UIViewRepresentable 메서드 - SwiftUI가 갱신될 때 Coordinator가 최신 callback을 사용하도록 동기화합니다.
    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        context.coordinator.onCameraCenterChanged = onCameraCenterChanged
        context.coordinator.onLocationError = onLocationError
        context.coordinator.requestCurrentLocationIfNeeded(
            for: locationRequestID,
            mapView: uiView.mapView
        )
    }

    /// UIViewRepresentable 메서드 - Representable이 제거될 때 등록했던 카메라 delegate를 해제합니다.
    static func dismantleUIView(_ uiView: NMFNaverMapView, coordinator: Coordinator) {
        uiView.mapView.removeCameraDelegate(delegate: coordinator)
        coordinator.cancelLocationRequest()
    }

    /// 네이버 지도 카메라 delegate 이벤트를 SwiftUI callback으로 변환합니다.
    final class Coordinator: NSObject {
        /// 상위 SwiftUI 화면이 제공한 최신 중심 좌표 수신 callback입니다.
        var onCameraCenterChanged: (MapCameraCenter) -> Void

        /// 위치 권한 및 위치 조회 실패를 상위 SwiftUI 화면에 알리는 callback입니다.
        var onLocationError: (LocationFailure) -> Void

        /// 위치 권한을 요청하고 한 번의 현재 위치를 수신하는 Core Location 관리자입니다.
        private let locationManager = CLLocationManager()

        /// `updateUIView`의 반복 호출로 같은 위치 요청이 중복 실행되지 않도록 보관하는 식별자입니다.
        private var handledLocationRequestID: UUID?

        /// 권한 응답 또는 위치 수신을 기다리는 현재 위치 요청이 있는지 나타냅니다.
        private var isLocationRequestPending = false

        /// 위치를 수신한 뒤 카메라를 이동할 지도입니다. Representable 수명주기를 넘겨 보관하지 않도록 약한 참조를 사용합니다.
        private weak var mapView: NMFMapView?

        /// 초기화 메서드 - 카메라 중심과 위치 오류 callback을 보관하고 위치 관리자 delegate를 연결합니다.
        init(
            onCameraCenterChanged: @escaping (MapCameraCenter) -> Void,
            onLocationError: @escaping (LocationFailure) -> Void
        ) {
            self.onCameraCenterChanged = onCameraCenterChanged
            self.onLocationError = onLocationError

            super.init()
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        }

        /// 사용자 정의 메서드 - 새 요청 식별자에 대해 권한 상태에 맞춰 현재 위치 조회를 시작합니다.
        func requestCurrentLocationIfNeeded(
            for requestID: UUID?,
            mapView: NMFMapView
        ) {
            guard let requestID,
                  requestID != handledLocationRequestID else {
                return
            }

            handledLocationRequestID = requestID
            isLocationRequestPending = true
            self.mapView = mapView

            switch locationManager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                locationManager.requestLocation()
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            case .denied, .restricted:
                reportLocationError(.permissionDenied)
            @unknown default:
                reportLocationError(.unavailable)
            }
        }

        /// 사용자 정의 메서드 - 화면 제거 시 대기 중인 위치 요청과 지도 참조를 정리합니다.
        func cancelLocationRequest() {
            isLocationRequestPending = false
            mapView = nil
        }

        /// 사용자 정의 메서드 - 위치 관련 오류를 다음 SwiftUI 업데이트 사이클에서 상위 화면으로 전달합니다.
        private func reportLocationError(_ failure: LocationFailure) {
            isLocationRequestPending = false

            DispatchQueue.main.async { [weak self] in
                self?.onLocationError(failure)
            }
        }
    }
}

extension NaverMapDemoView.Coordinator: NMFMapViewCameraDelegate {
    /// NMFMapViewCameraDelegate 메서드 - 카메라 이동과 애니메이션이 끝났을 때 최종 중심 좌표를 전달합니다.
    func mapViewCameraIdle(_ mapView: NMFMapView) {
        let target = mapView.cameraPosition.target
        let center = MapCameraCenter(latitude: target.lat, longitude: target.lng)

        DispatchQueue.main.async { [weak self] in
            self?.onCameraCenterChanged(center)
        }
    }
}

extension NaverMapDemoView.Coordinator: CLLocationManagerDelegate {
    /// CLLocationManagerDelegate 메서드 - 권한 상태가 바뀐 뒤 대기 중인 요청을 재개하거나 오류를 알립니다.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard isLocationRequestPending else { return }

        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied, .restricted:
            reportLocationError(.permissionDenied)
        case .notDetermined:
            break
        @unknown default:
            reportLocationError(.unavailable)
        }
    }

    /// CLLocationManagerDelegate 메서드 - 현재 위치를 받은 뒤 해당 좌표로 네이버 지도 카메라를 이동합니다.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isLocationRequestPending,
              let location = locations.last,
              let mapView else {
            return
        }

        isLocationRequestPending = false

        let coordinate = NMGLatLng(
            lat: location.coordinate.latitude,
            lng: location.coordinate.longitude
        )

        // 네이버 기본 내 위치 마커를 현재 수신한 좌표로 이동합니다.
        mapView.locationOverlay.location = coordinate

        // 기본 내 위치 마커가 숨겨져 있으면 지도에 표시합니다.
        mapView.locationOverlay.hidden = false

        let update = NMFCameraUpdate(scrollTo: coordinate, zoomTo: 15)
        update.animation = .easeIn
        mapView.moveCamera(update)
    }

    /// CLLocationManagerDelegate 메서드 - 위치 조회 실패를 상위 SwiftUI 화면에 전달합니다.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        reportLocationError(.unavailable)
    }
}

/// 현재 위치 이동 실패의 원인에 맞는 사용자 안내를 정의합니다.
private enum LocationFailure {
    case permissionDenied
    case unavailable

    var title: String {
        switch self {
        case .permissionDenied:
            "위치 권한이 필요합니다"
        case .unavailable:
            "현재 위치를 가져올 수 없습니다"
        }
    }

    var message: String {
        switch self {
        case .permissionDenied:
            "현재 위치로 이동하려면 설정에서 위치 권한을 허용해 주세요."
        case .unavailable:
            "잠시 후 다시 시도해 주세요."
        }
    }

    var requiresSettings: Bool {
        self == .permissionDenied
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
