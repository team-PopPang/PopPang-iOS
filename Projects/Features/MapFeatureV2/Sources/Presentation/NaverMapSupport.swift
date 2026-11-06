import Core
import CoreLocation
import Domain
import Kingfisher
import NMapsMap
import SwiftUI
import UIKit

struct NaverMapView: UIViewRepresentable {
    var popups: [Popup]
    var selectedPopupUuid: String?

    func makeCoordinator() -> NaverMapCoordinator {
        NaverMapCoordinator.shared
    }

    func makeUIView(context: Context) -> NMFNaverMapView {
        context.coordinator.getNaverMapView()
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        context.coordinator.updateSpots(popups)
        context.coordinator.updateSelection(selectedPopupUuid)
    }
}

final class NaverMapCoordinator: NSObject, NMFMapViewCameraDelegate, NMFMapViewTouchDelegate {
    static let shared = NaverMapCoordinator()

    private let view = NMFNaverMapView(frame: .zero)
    private var popups: [Popup] = []
    private var selectedPopupUuid: String?
    private var clusterer: NMCClusterer<ItemKey>?
    private var markers: [Int: (marker: NMFMarker, key: ItemKey)] = [:]
    private var leafUpdater: LeafMarkerUpdater?
    /// 마커 사진. 선택이 바뀔 때마다 다시 받지 않도록 주소별로 들고 있는다.
    private var thumbnails: [String: UIImage] = [:]
    /// 받는 중인 사진 주소. 같은 사진을 여러 번 요청하지 않는다.
    private var loadingThumbnails: Set<String> = []

    var onMarkerSelected: ((Popup) -> Void)?
    var onMapTapped: (() -> Void)?
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

    func moveToUserLocation(zoomLevel: Double = 15, yOffset: CGFloat = 0) {
        enableUserTracking()
        view.mapView.contentInset = yOffset == 0 ? .zero : UIEdgeInsets(top: yOffset, left: 0, bottom: 0, right: 0)

        let coord = view.mapView.locationOverlay.location
        let cameraPosition = NMFCameraPosition(coord, zoom: zoomLevel, tilt: 0, heading: 0)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }

    func moveToUserLocation(to coordinate: CLLocationCoordinate2D, zoomLevel: Double = 15) {
        enableUserTracking()
        let coord = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        view.mapView.locationOverlay.location = coord

        let cameraPosition = NMFCameraPosition(coord, zoom: zoomLevel, tilt: 0, heading: 0)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }

    func showUserLocationOverlay() {
        view.mapView.locationOverlay.hidden = false
    }

    func enableUserTracking() {
        showUserLocationOverlay()
        view.mapView.positionMode = .direction
    }

    func disableUserTracking() {
        view.mapView.positionMode = .normal
    }

    /// 팝업 목록이 바뀌면 마커를 다시 만든다. 찜처럼 위치·이름·사진이 그대로인 변경은 다시 만들지 않는다.
    func updateSpots(_ newPopups: [Popup]) {
        let isSameMarkers = newPopups.count == popups.count
            && zip(newPopups, popups).allSatisfy { new, old in
                new.popupUuid == old.popupUuid
                    && new.latitude == old.latitude
                    && new.longitude == old.longitude
                    && new.name == old.name
                    && new.imageUrlList.first == old.imageUrlList.first
            }
        popups = newPopups
        guard isSameMarkers == false else { return }
        makeClusterer()
    }

    /// 고른 마커는 크게, 나머지는 흐리게 다시 그린다. 고른 팝업이 없으면 모두 보통 크기로 돌린다.
    func updateSelection(_ popupUuid: String?) {
        guard popupUuid != selectedPopupUuid else { return }
        selectedPopupUuid = popupUuid
        for (_, entry) in markers {
            applyMarkerImage(entry.marker, key: entry.key)
        }
    }

    func moveCamera(to popup: Popup, zoomLevel: Double = 15, yOffset: CGFloat = 0) {
        guard let lat = popup.latitude, let lng = popup.longitude else { return }
        disableUserTracking()

        view.mapView.contentInset = yOffset == 0 ? .zero : UIEdgeInsets(top: yOffset, left: 0, bottom: 0, right: 0)

        let update = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng), zoomTo: zoomLevel)
        update.animation = .easeIn
        view.mapView.moveCamera(update)
    }

    func mapViewCameraIdle(_ mapView: NMFMapView) {
        let center = mapView.cameraPosition.target
        DispatchQueue.main.async {
            self.onCenterChanged?(MapCoordinate(latitude: center.lat, longitude: center.lng))
        }
    }

    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        onMapTapped?()
    }

    private func setupMap() {
        view.mapView.addCameraDelegate(delegate: self)
        view.mapView.touchDelegate = self
        view.mapView.zoomLevel = 10
        view.mapView.minZoomLevel = 5
        view.mapView.maxZoomLevel = 20
        view.mapView.positionMode = .normal
        view.mapView.isNightModeEnabled = false
        view.showLocationButton = false
        view.showZoomControls = false
        view.showCompass = false
        view.showScaleBar = false
        view.mapView.logoAlign = .rightBottom
        view.mapView.logoMargin = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 20)

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
        leafUpdater.onMarkerUpdated = { [weak self] marker, key in
            guard let self else { return }
            markers[key.identifier] = (marker, key)
            applyMarkerImage(marker, key: key)
            marker.touchHandler = { [weak self] _ in
                guard let self, key.identifier < popups.count else { return true }
                onMarkerSelected?(popups[key.identifier])
                return true
            }
        }
        builder.leafMarkerUpdater = leafUpdater
        builder.clusterMarkerUpdater = ClusterMarkerUpdater()
        builder.minZoom = 5
        builder.maxZoom = 12

        clusterer = builder.build()

        var keyTagMap: [ItemKey: NSObject] = [:]
        for (index, popup) in popups.enumerated() {
            guard let lat = popup.latitude, let lng = popup.longitude else { continue }
            let key = ItemKey(
                identifier: index,
                popupUuid: popup.popupUuid,
                name: popup.name,
                position: NMGLatLng(lat: lat, lng: lng),
                imageURL: popup.imageUrlList.first
            )
            keyTagMap[key] = NSNull()
        }
        clusterer?.addAll(keyTagMap)
        clusterer?.mapView = view.mapView
    }

    private func applyMarkerImage(_ marker: NMFMarker, key: ItemKey) {
        let style: MapMarkerRenderer.Style
        if let selectedPopupUuid {
            style = selectedPopupUuid == key.popupUuid ? .selected : .dimmed
        } else {
            style = .normal
        }

        let thumbnail = key.imageURL.flatMap { thumbnails[$0] }
        let rendered = MapMarkerRenderer.image(thumbnail: thumbnail, name: key.name, style: style)
        marker.iconImage = NMFOverlayImage(image: rendered.image)
        marker.width = rendered.image.size.width
        marker.height = rendered.image.size.height
        // 좌표가 링 가운데에 오게 한다.
        marker.anchor = CGPoint(x: 0.5, y: rendered.ringCenterY / rendered.image.size.height)
        marker.zIndex = style == .selected ? 999_999 : 0

        guard thumbnail == nil,
              let imageURL = key.imageURL,
              let url = URL(string: imageURL),
              loadingThumbnails.contains(imageURL) == false
        else { return }
        loadingThumbnails.insert(imageURL)
        Task { [weak self] in
            let result = try? await KingfisherManager.shared.retrieveImage(with: url)
            await MainActor.run {
                guard let self else { return }
                self.loadingThumbnails.remove(imageURL)
                guard let result else { return }
                self.thumbnails[imageURL] = result.image
                // 사진을 기다린 마커들을 다시 그린다.
                for (_, entry) in self.markers where entry.key.imageURL == imageURL {
                    self.applyMarkerImage(entry.marker, key: entry.key)
                }
            }
        }
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
            NaverMapCoordinator.shared.showUserLocationOverlay()
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
            NaverMapCoordinator.shared.showUserLocationOverlay()
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
    let popupUuid: String
    let name: String
    let position: NMGLatLng
    let imageURL: String?

    init(identifier: Int, popupUuid: String, name: String, position: NMGLatLng, imageURL: String?) {
        self.identifier = identifier
        self.popupUuid = popupUuid
        self.name = name
        self.position = position
        self.imageURL = imageURL
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
        ItemKey(identifier: identifier, popupUuid: popupUuid, name: name, position: position, imageURL: imageURL)
    }
}

/// 가까운 마커를 묶은 숫자 원. 피그마의 빨간 원과 흰 숫자다.
final class ClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    override func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        super.updateClusterMarker(info, marker)
        let image = MapMarkerRenderer.clusterImage(count: Int(info.size))
        marker.iconImage = NMFOverlayImage(image: image)
        marker.width = image.size.width
        marker.height = image.size.height
        marker.anchor = CGPoint(x: 0.5, y: 0.5)
        marker.captionText = ""
    }
}

final class LeafMarkerUpdater: NMCDefaultLeafMarkerUpdater {
    var onMarkerUpdated: ((NMFMarker, ItemKey) -> Void)?

    override func updateLeafMarker(_ info: NMCLeafMarkerInfo, _ marker: NMFMarker) {
        super.updateLeafMarker(info, marker)
        guard let key = info.key as? ItemKey else { return }
        onMarkerUpdated?(marker, key)
    }
}

/// 마커 그림. 사진 + 상태 색 테두리 원 아래에 이름 말풍선을 붙인다.
enum MapMarkerRenderer {
    enum Style {
        case normal
        case selected
        case dimmed
    }

    struct Rendered {
        let image: UIImage
        let ringCenterY: CGFloat
    }

    /// 운영 중 테두리 색. 상태별 색(오늘 종료·오픈 예정)은 서버가 상태 값을 주면 나눈다.
    static let ringColor = UIColor(red: 0x22 / 255, green: 0xA3 / 255, blue: 0x5A / 255, alpha: 1)
    static let selectedRingColor = UIColor(red: 0xE5 / 255, green: 0x35 / 255, blue: 0x2B / 255, alpha: 1)
    static let clusterColor = UIColor(red: 0xA3 / 255, green: 0x17 / 255, blue: 0x2B / 255, alpha: 1)
    static let textColor = UIColor(red: 0x19 / 255, green: 0x19 / 255, blue: 0x19 / 255, alpha: 1)

    static func image(thumbnail: UIImage?, name: String, style: Style) -> Rendered {
        let isSelected = style == .selected
        let ring: CGFloat = isSelected ? 58 : 46
        let ringWidth: CGFloat = isSelected ? 4 : 3
        let thumbInset: CGFloat = isSelected ? 7 : 6
        let font = UIFont.systemFont(ofSize: isSelected ? 13 : 11, weight: .bold)
        let labelHeight: CGFloat = isSelected ? 24 : 19
        let gap: CGFloat = 3
        let shadow: CGFloat = 3

        let text = name as NSString
        let textSize = text.size(withAttributes: [.font: font])
        let labelWidth = min(textSize.width + 16, 140)
        let width = max(ring, labelWidth) + shadow * 2
        let height = ring + gap + labelHeight + shadow * 2

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            if style == .dimmed { cg.setAlpha(0.55) }

            let ringRect = CGRect(x: (width - ring) / 2, y: shadow, width: ring, height: ring)
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 0, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.2).cgColor)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: ringRect).fill()
            cg.restoreGState()

            let thumbRect = ringRect.insetBy(dx: thumbInset, dy: thumbInset)
            cg.saveGState()
            UIBezierPath(ovalIn: thumbRect).addClip()
            if let thumbnail {
                let scale = max(thumbRect.width / thumbnail.size.width, thumbRect.height / thumbnail.size.height)
                let size = CGSize(width: thumbnail.size.width * scale, height: thumbnail.size.height * scale)
                thumbnail.draw(in: CGRect(
                    x: thumbRect.midX - size.width / 2,
                    y: thumbRect.midY - size.height / 2,
                    width: size.width,
                    height: size.height
                ))
            } else {
                UIColor(white: 0.92, alpha: 1).setFill()
                UIRectFill(thumbRect)
            }
            cg.restoreGState()

            let border = UIBezierPath(ovalIn: ringRect.insetBy(dx: ringWidth / 2, dy: ringWidth / 2))
            border.lineWidth = ringWidth
            (isSelected ? selectedRingColor : ringColor).setStroke()
            border.stroke()

            let labelRect = CGRect(x: (width - labelWidth) / 2, y: ringRect.maxY + gap, width: labelWidth, height: labelHeight)
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 0, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.15).cgColor)
            UIColor.white.setFill()
            UIBezierPath(roundedRect: labelRect, cornerRadius: 8).fill()
            cg.restoreGState()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byTruncatingTail
            let textRect = CGRect(
                x: labelRect.minX + 8,
                y: labelRect.midY - textSize.height / 2,
                width: labelRect.width - 16,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: [.font: font, .foregroundColor: textColor, .paragraphStyle: paragraph])
        }
        return Rendered(image: image, ringCenterY: shadow + ring / 2)
    }

    static func clusterImage(count: Int) -> UIImage {
        let size: CGFloat = 44
        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size + 6, height: size + 6), format: format)
        return renderer.image { context in
            let rect = CGRect(x: 3, y: 3, width: size, height: size)
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.25).cgColor)
            clusterColor.setFill()
            UIBezierPath(ovalIn: rect).fill()
            context.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            let border = UIBezierPath(ovalIn: rect.insetBy(dx: 1, dy: 1))
            border.lineWidth = 2
            UIColor.white.setStroke()
            border.stroke()

            let text = "\(count)" as NSString
            let font = UIFont.systemFont(ofSize: 15, weight: .bold)
            let textSize = text.size(withAttributes: [.font: font])
            text.draw(
                at: CGPoint(x: rect.midX - textSize.width / 2, y: rect.midY - textSize.height / 2),
                withAttributes: [.font: font, .foregroundColor: UIColor.white]
            )
        }
    }
}
