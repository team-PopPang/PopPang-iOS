import Core
import CoreLocation
import Domain
import NMapsMap
import SwiftUI
import UIKit

struct NaverMapView: UIViewRepresentable {
    var popups: [Popup]
    /// 팝업별 마커 색(`#RRGGBB`). 없는 팝업은 회색으로 그린다.
    var markerColors: [String: String]
    var selectedPopupUuid: String?

    func makeCoordinator() -> NaverMapCoordinator {
        NaverMapCoordinator.shared
    }

    func makeUIView(context: Context) -> NMFNaverMapView {
        context.coordinator.getNaverMapView()
    }

    func updateUIView(_ uiView: NMFNaverMapView, context: Context) {
        context.coordinator.updateSpots(popups, markerColors: markerColors)
        context.coordinator.updateSelection(selectedPopupUuid)
    }
}

final class NaverMapCoordinator: NSObject, NMFMapViewCameraDelegate, NMFMapViewTouchDelegate {
    static let shared = NaverMapCoordinator()

    /// 이 줌부터 마커 아래에 팝업 이름을 보인다. 숫자 묶음은 줌 12까지라, 13은 동그라미만 보이고 14부터 이름이 붙는다.
    /// 내 위치로 옮길 때 기본 줌(15)에서는 이름이 보인다. 고른 마커는 줌과 상관없이 이름을 보인다.
    static let labelMinZoom: Double = 14

    private let view = NMFNaverMapView(frame: .zero)
    private var popups: [Popup] = []
    private var markerColors: [String: String] = [:]
    /// 지금 줌에서 마커 이름을 보이는지. `labelMinZoom`을 넘나들 때만 마커를 다시 그린다.
    private var showsLabels = false
    private var selectedPopupUuid: String?
    private var clusterer: NMCClusterer<ItemKey>?
    /// 지금 팝업 마커로 그려진 마커. 클러스터러가 마커 객체를 다시 쓰므로 마커 객체 기준으로 들고 있는다.
    private var markers: [ObjectIdentifier: (marker: NMFMarker, key: ItemKey)] = [:]
    private var leafUpdater: LeafMarkerUpdater?
    private var clusterUpdater: ClusterMarkerUpdater?

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

    /// 팝업 목록이나 마커 색이 바뀌면 마커를 다시 만든다. 찜처럼 위치·이름·색이 그대로인 변경은 다시 만들지 않는다.
    /// 색은 카테고리를 늦게 받았거나 카테고리 필터를 바꾸면 달라진다.
    func updateSpots(_ newPopups: [Popup], markerColors newColors: [String: String]) {
        let isSameMarkers = newColors == markerColors
            && newPopups.count == popups.count
            && zip(newPopups, popups).allSatisfy { new, old in
                new.popupUuid == old.popupUuid
                    && new.latitude == old.latitude
                    && new.longitude == old.longitude
                    && new.name == old.name
            }
        popups = newPopups
        markerColors = newColors
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

    func mapView(_ mapView: NMFMapView, cameraIsChangingByReason reason: Int) {
        updateLabelVisibility(zoomLevel: mapView.zoomLevel)
    }

    /// 줌이 `labelMinZoom`을 넘나들면 모든 팝업 마커를 이름이 있게·없게 다시 그린다.
    private func updateLabelVisibility(zoomLevel: Double) {
        let shows = zoomLevel >= Self.labelMinZoom
        guard shows != showsLabels else { return }
        showsLabels = shows
        for (_, entry) in markers {
            applyMarkerImage(entry.marker, key: entry.key)
        }
    }

    func mapViewCameraIdle(_ mapView: NMFMapView) {
        updateLabelVisibility(zoomLevel: mapView.zoomLevel)
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
            // 클러스터러는 마커 객체를 다른 팝업에 다시 쓴다. 마커 객체 기준으로 덮어써서 지난 팝업 정보가 남지 않는다.
            markers[ObjectIdentifier(marker)] = (marker, key)
            applyMarkerImage(marker, key: key)
            marker.touchHandler = { [weak self] _ in
                guard let self, key.identifier < popups.count else { return true }
                onMarkerSelected?(popups[key.identifier])
                return true
            }
        }
        builder.leafMarkerUpdater = leafUpdater
        let clusterUpdater = ClusterMarkerUpdater()
        // 같은 마커 객체가 숫자 묶음으로 다시 쓰이면 팝업 마커 목록에서 뺀다. 빼지 않으면 선택이 바뀔 때 숫자 원을 팝업 마커로 다시 그린다.
        clusterUpdater.onClusterUpdated = { [weak self] marker in
            self?.markers.removeValue(forKey: ObjectIdentifier(marker))
        }
        self.clusterUpdater = clusterUpdater
        builder.clusterMarkerUpdater = clusterUpdater
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
                colorHex: markerColors[popup.popupUuid]
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

        let rendered = MapMarkerRenderer.image(
            colorHex: key.colorHex,
            name: key.name,
            style: style,
            showsLabel: showsLabels || style == .selected
        )
        marker.iconImage = NMFOverlayImage(image: rendered.image)
        marker.width = rendered.image.size.width
        marker.height = rendered.image.size.height
        // 좌표가 링 가운데에 오게 한다.
        marker.anchor = CGPoint(x: 0.5, y: rendered.ringCenterY / rendered.image.size.height)
        marker.zIndex = style == .selected ? 999_999 : 0
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
        guard let location = locations.last else { return }
        // 카메라는 처음 한 번만 옮기고, 위치는 받을 때마다 알린다. 화면이 다시 나타나 기다리는 가까운순 조회도 위치를 받는다.
        publishLocation(location, moveCamera: hasMovedToUserLocation == false)
        hasMovedToUserLocation = true
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
    /// 마커 색(`#RRGGBB`). 맞는 카테고리가 없으면 `nil`이다.
    let colorHex: String?

    init(identifier: Int, popupUuid: String, name: String, position: NMGLatLng, colorHex: String?) {
        self.identifier = identifier
        self.popupUuid = popupUuid
        self.name = name
        self.position = position
        self.colorHex = colorHex
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
        ItemKey(identifier: identifier, popupUuid: popupUuid, name: name, position: position, colorHex: colorHex)
    }
}

/// 가까운 마커를 묶은 숫자 원. 피그마의 빨간 원과 흰 숫자다.
final class ClusterMarkerUpdater: NMCDefaultClusterMarkerUpdater {
    var onClusterUpdated: ((NMFMarker) -> Void)?

    override func updateClusterMarker(_ info: NMCClusterMarkerInfo, _ marker: NMFMarker) {
        super.updateClusterMarker(info, marker)
        onClusterUpdated?(marker)
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

/// 마커 그림. 피그마 지도 화면(2467:10301)처럼 모양이 고정된 동그라미다.
/// 카테고리 색 테두리와 연한 같은 색 원 위에 갈색 가게 아이콘을 두고, 아래에 이름 말풍선을 붙인다.
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

    /// 맞는 카테고리가 없는 팝업의 색.
    static let fallbackColor = UIColor(red: 0x9E / 255, green: 0x9E / 255, blue: 0x9E / 255, alpha: 1)
    static let clusterColor = UIColor(red: 0xA3 / 255, green: 0x17 / 255, blue: 0x2B / 255, alpha: 1)
    static let textColor = UIColor(red: 0x19 / 255, green: 0x19 / 255, blue: 0x19 / 255, alpha: 1)

    /// 그린 마커. 같은 색·이름·모양이면 다시 그리지 않는다. 선택이 바뀔 때 모든 마커를 다시 그리므로 캐시해 둔다.
    private static let cache: NSCache<NSString, RenderedBox> = {
        let cache = NSCache<NSString, RenderedBox>()
        cache.countLimit = 500
        return cache
    }()

    private final class RenderedBox {
        let rendered: Rendered
        init(_ rendered: Rendered) { self.rendered = rendered }
    }

    static func image(colorHex: String?, name: String, style: Style, showsLabel: Bool) -> Rendered {
        let cacheKey = "\(colorHex ?? "-")|\(style)|\(showsLabel)|\(name)" as NSString
        if let cached = cache.object(forKey: cacheKey) { return cached.rendered }
        let rendered = draw(
            color: colorHex.flatMap(color(hex:)) ?? fallbackColor,
            name: showsLabel ? name : nil,
            style: style
        )
        cache.setObject(RenderedBox(rendered), forKey: cacheKey)
        return rendered
    }

    /// 서버 색(`#RRGGBB`)을 UIColor로 바꾼다. 형식이 다르면 `nil`이다.
    static func color(hex: String) -> UIColor? {
        var text = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        guard text.count == 6, let value = UInt32(text, radix: 16) else { return nil }
        return UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }

    /// 가게 아이콘. 피그마 `MapPin`의 `icon/store`(갈색)를 그대로 쓴다. 카테고리 색과 상관없이 같다.
    private static let storeIcon = UIImage(named: "map_marker_store", in: .module, with: nil)

    /// 피그마 `MapPin`(2467:10337) 치수. 고른 마커(2467:10435)는 1.35배다.
    /// `name`이 `nil`이면 이름표 없이 동그라미만 그린다.
    private static func draw(color: UIColor, name: String?, style: Style) -> Rendered {
        let scale: CGFloat = style == .selected ? 1.35 : 1
        let ring = 46 * scale
        let ringWidth = 4 * scale
        let thumbInset = 6 * scale
        let iconSize = 16 * scale
        let font = UIFont.systemFont(ofSize: 11 * scale, weight: .bold)
        let labelHeight = 19 * scale
        let labelRadius = 8 * scale
        let gap = 4 * scale
        let shadow: CGFloat = 3

        let text = name.map { $0 as NSString }
        let textSize = text?.size(withAttributes: [.font: font, .kern: -0.02 * font.pointSize]) ?? .zero
        let labelWidth = text == nil ? 0 : min(textSize.width + 16 * scale, 140 * scale)
        let width = max(ring, labelWidth) + shadow * 2
        let height = ring + shadow * 2 + (text == nil ? 0 : gap + labelHeight)

        let format = UIGraphicsImageRendererFormat()
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: format)
        let image = renderer.image { context in
            let cg = context.cgContext
            if style == .dimmed { cg.setAlpha(0.55) }

            // 흰 원(그림자) → 카테고리 색 테두리 → 흰 띠 → 연한 카테고리 색 원 → 갈색 가게 아이콘
            let ringRect = CGRect(x: (width - ring) / 2, y: shadow, width: ring, height: ring)
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 0, height: 1), blur: 3, color: UIColor.black.withAlphaComponent(0.2).cgColor)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: ringRect).fill()
            cg.restoreGState()

            let border = UIBezierPath(ovalIn: ringRect.insetBy(dx: ringWidth / 2, dy: ringWidth / 2))
            border.lineWidth = ringWidth
            color.setStroke()
            border.stroke()

            let thumbRect = ringRect.insetBy(dx: thumbInset, dy: thumbInset)
            tint(color).setFill()
            UIBezierPath(ovalIn: thumbRect).fill()

            storeIcon?.draw(in: CGRect(
                x: thumbRect.midX - iconSize / 2,
                y: thumbRect.midY - iconSize / 2,
                width: iconSize,
                height: iconSize
            ))

            guard let text else { return }
            let labelRect = CGRect(x: (width - labelWidth) / 2, y: ringRect.maxY + gap, width: labelWidth, height: labelHeight)
            cg.saveGState()
            cg.setShadow(offset: CGSize(width: 0, height: 1), blur: 2, color: UIColor.black.withAlphaComponent(0.15).cgColor)
            UIColor.white.setFill()
            UIBezierPath(roundedRect: labelRect, cornerRadius: labelRadius).fill()
            cg.restoreGState()

            let paragraph = NSMutableParagraphStyle()
            paragraph.alignment = .center
            paragraph.lineBreakMode = .byTruncatingTail
            let textRect = CGRect(
                x: labelRect.minX + 8 * scale,
                y: labelRect.midY - textSize.height / 2,
                width: labelRect.width - 16 * scale,
                height: textSize.height
            )
            text.draw(in: textRect, withAttributes: [
                .font: font,
                .kern: -0.02 * font.pointSize,
                .foregroundColor: textColor,
                .paragraphStyle: paragraph,
            ])
        }
        return Rendered(image: image, ringCenterY: shadow + ring / 2)
    }

    /// 안쪽 원 색. 피그마는 테두리 색을 흰색에 약 30% 섞은 연한 색이다(예: `#22A35A` → `#C9DDB9`).
    private static func tint(_ color: UIColor) -> UIColor {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else { return color.withAlphaComponent(0.3) }
        let amount: CGFloat = 0.3
        return UIColor(
            red: 1 - (1 - red) * amount,
            green: 1 - (1 - green) * amount,
            blue: 1 - (1 - blue) * amount,
            alpha: 1
        )
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
