import Core
import CoreLocation
import Domain
import Kingfisher
import NMapsMap
import SwiftUI
import UIKit

struct NaverMapView: UIViewRepresentable {
    var popups: [Popup]

    func makeCoordinator() -> NaverMapCoordinator {
        NaverMapCoordinator.shared
    }

    func makeUIView(context: Context) -> NMFNaverMapView {
        context.coordinator.getNaverMapView()
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        context.coordinator.updateSpots(popups)
    }
}

final class NaverMapCoordinator: NSObject, CLLocationManagerDelegate, NMFMapViewCameraDelegate {
    static let shared = NaverMapCoordinator()

    private let view = NMFNaverMapView(frame: .zero)
    private var locationManager: CLLocationManager?
    private var popups: [Popup] = []
    private var clusterer: NMCClusterer<ItemKey>?
    private var markers: [Int: NMFMarker] = [:]
    private var leafUpdater: LeafMarkerUpdater?

    var onMarkerSelected: ((ItemKey, Popup) -> Void)?
    var onCenterChanged: ((MapCoordinate) -> Void)?

    override init() {
        super.init()
        setupMap()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.makeClusterer()
            self.moveToUserLocation(yOffset: -300)
        }
    }

    func getNaverMapView() -> NMFNaverMapView {
        view
    }

    func currentCenter() -> MapCoordinate {
        let center = view.mapView.cameraPosition.target
        return MapCoordinate(latitude: center.lat, longitude: center.lng)
    }

    func checkIfLocationServiceIsEnabled() {
        DispatchQueue.global().async {
            guard CLLocationManager.locationServicesEnabled() else {
                Logger.w("위치 서비스가 꺼져 있습니다.")
                return
            }

            DispatchQueue.main.async {
                self.locationManager = CLLocationManager()
                self.locationManager?.delegate = self
                self.locationManager?.desiredAccuracy = kCLLocationAccuracyBest
            }
        }
    }

    func moveToUserLocation(zoomLevel: Double = 15, yOffset: CGFloat = 0) {
        view.mapView.contentInset = yOffset == 0 ? .zero : UIEdgeInsets(top: yOffset, left: 0, bottom: 0, right: 0)

        let coord = view.mapView.locationOverlay.location
        let cameraPosition = NMFCameraPosition(coord, zoom: zoomLevel, tilt: 0, heading: 0)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }

    func moveToUserLocation(to coordinate: CLLocationCoordinate2D, zoomLevel: Double = 15) {
        let coord = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        view.mapView.locationOverlay.location = coord

        let cameraPosition = NMFCameraPosition(coord, zoom: zoomLevel, tilt: 0, heading: 0)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }

    func enableUserLocationOverlay() {
        view.mapView.positionMode = .direction
        view.mapView.locationOverlay.hidden = false
    }

    func updateSpots(_ newPopups: [Popup]) {
        guard newPopups != popups else { return }
        popups = newPopups
        makeClusterer()
    }

    func moveCamera(to popup: Popup, zoomLevel: Double = 15, yOffset: CGFloat = 0) {
        guard let lat = popup.latitude, let lng = popup.longitude else { return }

        view.mapView.contentInset = yOffset == 0 ? .zero : UIEdgeInsets(top: yOffset, left: 0, bottom: 0, right: 0)

        let update = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng), zoomTo: zoomLevel)
        update.animation = .easeIn
        view.mapView.moveCamera(update)
    }

    func focusMarker(identifier: Int) {
        guard let marker = markers[identifier] else { return }

        for (_, marker) in markers {
            marker.zIndex = 0
        }

        marker.zIndex = 999_999
    }

    func mapViewCameraIdle(_ mapView: NMFMapView) {
        let center = mapView.cameraPosition.target
        DispatchQueue.main.async {
            self.onCenterChanged?(MapCoordinate(latitude: center.lat, longitude: center.lng))
        }
    }

    private func setupMap() {
        view.mapView.addCameraDelegate(delegate: self)
        view.mapView.zoomLevel = 10
        view.mapView.minZoomLevel = 5
        view.mapView.maxZoomLevel = 20
        view.mapView.positionMode = .direction
        view.mapView.isNightModeEnabled = false
        view.showLocationButton = false
        view.showZoomControls = false
        view.showCompass = true
        view.showScaleBar = false
        view.mapView.logoAlign = .leftBottom
        view.mapView.logoMargin = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 0)

        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: 37.5665, lng: 126.9780))
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }

    private func makeClusterer() {
        clusterer?.clear()
        clusterer = nil
        markers.removeAll()

        let builder = NMCBuilder<ItemKey>()

        let leafUpdater = LeafMarkerUpdater()
        self.leafUpdater = leafUpdater
        leafUpdater.onMarkerCreated = { [weak self] marker, key in
            self?.markers[key.identifier] = marker
        }
        leafUpdater.onMarkerSelected = { [weak self] key in
            guard let self, key.identifier < popups.count else { return }
            focusMarker(identifier: key.identifier)
            onMarkerSelected?(key, popups[key.identifier])
        }
        builder.leafMarkerUpdater = leafUpdater
        builder.clusterMarkerUpdater = ClusterMarkerUpdater()
        builder.minZoom = 5
        builder.maxZoom = 12

        clusterer = builder.build()

        var keyTagMap: [ItemKey: NSObject] = [:]
        for (index, popup) in popups.enumerated() {
            guard let imageURL = popup.imageUrlList.first else { continue }
            let key = ItemKey(
                identifier: index,
                position: NMGLatLng(lat: popup.latitude ?? 0, lng: popup.longitude ?? 0),
                imageURL: imageURL
            )
            keyTagMap[key] = NSNull()
        }
        clusterer?.addAll(keyTagMap)
        clusterer?.mapView = view.mapView
    }
}

final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()

    private let locationManager = CLLocationManager()
    private var hasMovedToUserLocation = false
    var onPermissionDenied: (() -> Void)?
    var onLocationUpdated: ((MapCoordinate) -> Void)?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestPermission() {
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            emitCurrentLocationIfAvailable(moveCamera: false)
            locationManager.startUpdatingLocation()
            NaverMapCoordinator.shared.enableUserLocationOverlay()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            onPermissionDenied?()
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Logger.d("위치 권한 허용됨")
            emitCurrentLocationIfAvailable(moveCamera: false)
            locationManager.startUpdatingLocation()
            NaverMapCoordinator.shared.enableUserLocationOverlay()
        case .denied, .restricted:
            Logger.e("위치 권한 거부됨")
            DispatchQueue.main.async {
                self.onPermissionDenied?()
            }
        case .notDetermined:
            Logger.w("아직 권한 선택 전")
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, hasMovedToUserLocation == false else { return }
        hasMovedToUserLocation = true

        publishLocation(location, moveCamera: true)
        manager.stopUpdatingLocation()
    }

    private func emitCurrentLocationIfAvailable(moveCamera: Bool) {
        guard let location = locationManager.location else { return }
        publishLocation(location, moveCamera: moveCamera)
    }

    private func publishLocation(_ location: CLLocation, moveCamera: Bool) {
        let coordinate = MapCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        DispatchQueue.main.async {
            self.onLocationUpdated?(coordinate)
        }

        if moveCamera {
            NaverMapCoordinator.shared.moveToUserLocation(to: location.coordinate)
        }
    }
}

final class ItemKey: NSObject, NMCClusteringKey {
    let identifier: Int
    let position: NMGLatLng
    let imageURL: String

    init(identifier: Int, position: NMGLatLng, imageURL: String) {
        self.identifier = identifier
        self.position = position
        self.imageURL = imageURL
    }

    static func markerKey(withIdentifier identifier: Int, position: NMGLatLng, imageURL: String) -> ItemKey {
        ItemKey(identifier: identifier, position: position, imageURL: imageURL)
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? ItemKey else { return false }
        if self === object { return true }
        return object.identifier == identifier
    }

    override var hash: Int {
        identifier
    }

    func copy(with zone: NSZone? = nil) -> Any {
        ItemKey(identifier: identifier, position: position, imageURL: imageURL)
    }
}

final class ClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    override func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        super.updateClusterMarker(info, marker)

        if info.size < 3 {
            marker.iconImage = NMF_MARKER_IMAGE_CLUSTER_LOW_DENSITY
        } else {
            marker.iconImage = NMF_MARKER_IMAGE_CLUSTER_MEDIUM_DENSITY
        }
    }
}

final class LeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    var onMarkerSelected: ((ItemKey) -> Void)?
    var onMarkerCreated: ((NMFMarker, ItemKey) -> Void)?

    override func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        super.updateLeafMarker(info, marker)

        guard let key = info.key as? ItemKey,
              let imageURL = URL(string: key.imageURL) else { return }

        onMarkerCreated?(marker, key)

        Task {
            if let roundedImage = await makeRoundedMarkerImage(from: imageURL, size: CGSize(width: 60, height: 60)) {
                await MainActor.run {
                    marker.iconImage = NMFOverlayImage(image: roundedImage)
                    marker.width = 60
                    marker.height = 60
                }
            }
        }

        marker.touchHandler = { [weak self] _ in
            self?.onMarkerSelected?(key)
            return true
        }
    }

    private func makeRoundedMarkerImage(from url: URL, size: CGSize) async -> UIImage? {
        do {
            let result = try await KingfisherManager.shared.retrieveImage(with: url)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { _ in
                let rect = CGRect(origin: .zero, size: size)
                let path = UIBezierPath(roundedRect: rect, cornerRadius: 10)
                path.addClip()
                result.image.draw(in: rect)
            }
        } catch {
            Logger.e("이미지 로드 실패: \(error)")
            return nil
        }
    }
}
