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
    /// 보이는 영역 여백을 한 번이라도 반영했는지.
    private var hasAppliedInsets = false
    /// 여백 맞추기로 되돌아갈 중심. 되돌아가는 애니메이션 도중에 여백이 다시 바뀌면 중간 위치가 아니라 이 중심으로 간다.
    private var paddingReturnTarget: NMGLatLng?
    /// 마지막 코드 이동을 시작한 뒤 카메라가 (여백 맞추기가 아닌 이유로) 움직였는지.
    private var cameraChangedSinceMoveStart = false
    /// 화면이 정한 보이는 영역의 위·아래 여백. 위는 검색창·칩, 아래는 시트·카드가 가리는 높이다.
    /// 지도에는 그대로 넣지 않고 `mapInsets(for:)`로 바꿔 넣는다.
    private var visibleInsets = UIEdgeInsets.zero
    /// 지도 아래를 늘 가리는 높이(탭바). 지도의 아래 여백은 이 값으로 고정해 네이버 로고를 탭바 바로 위 오른쪽에 둔다.
    var fixedBottomInset: CGFloat = 0 {
        didSet {
            guard abs(fixedBottomInset - oldValue) > 0.5 else { return }
            // 보이는 영역의 가운데는 그대로라 카메라는 움직이지 않는다.
            isIssuingInsetMove = true
            view.mapView.setContentInset(mapInsets(for: visibleInsets), reason: Int32(NMFMapChangedByContentPadding))
            isIssuingInsetMove = false
        }
    }
    /// 지금 반영한 보이는 영역의 아래 여백(시트·카드가 가리는 높이).
    var contentBottomInset: CGFloat { visibleInsets.bottom }
    /// 지금 반영한 보이는 영역의 위 여백(검색창·칩이 가리는 높이).
    var contentTopInset: CGFloat { visibleInsets.top }

    /// 보이는 영역 여백을 지도의 콘텐츠 여백으로 바꾼다.
    /// 네이버 SDK는 로고를 콘텐츠 여백을 뺀 영역의 구석에 그리므로, 아래 여백을 시트 높이만큼 주면 로고가 시트 위로 떠오른다.
    /// 그래서 아래 여백은 탭바 높이로 고정하고, 시트·카드가 더 가리는 만큼 위 여백을 줄인다(음수 허용, 예전 지도도 위 여백을 음수로 썼다).
    /// 콘텐츠 영역의 가운데는 보이는 영역의 가운데와 같다.
    private func mapInsets(for visible: UIEdgeInsets) -> UIEdgeInsets {
        let bottom = fixedBottomInset
        return UIEdgeInsets(top: visible.top - (visible.bottom - bottom), left: 0, bottom: bottom, right: 0)
    }

    /// 받은 위치를 위치 오버레이에 넣는다. 카메라는 옮기지 않는다. 내 위치 버튼이 이 위치로 옮긴다.
    func updateLocationOverlay(_ coordinate: CLLocationCoordinate2D) {
        view.mapView.locationOverlay.location = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
    }
    /// 여백을 바꾸는 중인지. 그사이 멈춤 알림이 오면 중간 위치를 알리지 않고 도착점도 지우지 않는다.
    private var isIssuingInsetMove = false
    /// 마지막 멈춤 이후 보이는 영역 맞추기(콘텐츠 패딩)가 아닌 이동(손 제스처, 내 위치, 팝업 선택)이 있었는지.
    /// 멈췄을 때 이 값이 참일 때만 지도 중심 변경을 알린다. 마지막 원인 하나만 보면 패딩 이동이 앞선 제스처를 덮어쓴다.
    private var hasMeaningfulChangeSinceIdle = false
    /// 진행 중인 코드 이동(내 위치, 팝업 선택)의 도착점. 그사이 보이는 영역이 바뀌면 중간 위치가 아니라 이 도착점을 가운데로 둔다.
    private var pendingMoveTarget: NMGLatLng?
    /// 진행 중인 코드 이동의 도착 줌. 그사이 보이는 영역이 바뀌어도 이 줌까지 간다.
    private var pendingMoveZoom: Double?
    /// 마지막 멈춤 이후 손 제스처가 있었는지.
    private var hasGestureSinceIdle = false
    /// 마지막 코드 이동 이후 사용자가 손으로 지도를 움직였는지.
    private(set) var userMovedSinceProgrammaticMove = false
    private var clusterUpdater: ClusterMarkerUpdater?

    var onMarkerSelected: ((Popup) -> Void)?
    var onMapTapped: (() -> Void)?
    /// 지도가 멈췄을 때 중심과, 그사이 사용자가 손으로 움직였는지를 알린다.
    var onCenterChanged: ((MapCoordinate, _ byGesture: Bool) -> Void)?

    override init() {
        super.init()
        setupMap()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.makeClusterer()
            self.moveToUserLocation()
        }
    }

    func getNaverMapView() -> NMFNaverMapView {
        view
    }

    func moveToUserLocation(zoomLevel: Double = 15) {
        enableUserTracking()

        let coord = view.mapView.locationOverlay.location
        let cameraPosition = NMFCameraPosition(coord, zoom: zoomLevel, tilt: 0, heading: 0)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        Self.applyMoveAnimation(to: cameraUpdate)
        // 아직 위치를 받지 못했으면(위치 오버레이가 기본값 (0, 0)) 카메라를 옮기지 않고 도착점도 남기지 않는다.
        // 카메라가 움직이지 않으므로 손 이동 표시도 그대로 둔다. 위치를 받으면 추적 모드가 카메라를 옮긴다.
        guard Self.hasLocationFix(coord) else { return }
        startProgrammaticMove(to: coord, zoom: zoomLevel)
        view.mapView.moveCamera(cameraUpdate)
    }

    /// 위치 오버레이에 실제 위치가 들어 있는지. 위치를 받기 전 오버레이는 (0, 0)이다.
    private static func hasLocationFix(_ coord: NMGLatLng) -> Bool {
        let status = LocationPermissionManager.shared.authorizationStatus
        let authorized = status == .authorizedWhenInUse || status == .authorizedAlways
        return authorized && (abs(coord.lat) > 0.0001 || abs(coord.lng) > 0.0001)
    }

    /// 코드로 카메라를 옮기기 시작할 때 부른다. 도착점을 기억하고, 손 이동 표시를 지운다.
    private func startProgrammaticMove(to target: NMGLatLng, zoom: Double) {
        paddingReturnTarget = nil
        userMovedSinceProgrammaticMove = false
        cameraChangedSinceMoveStart = false
        // 손으로 밀던 지도가 미끄러지는 중에 코드로 옮기면 이 이동이 이어받는다. 멈췄을 때 손 이동으로 알리지 않는다.
        hasGestureSinceIdle = false
        // 이미 그 위치·줌이면 카메라가 움직이지 않아 멈춤이 오지 않는다. 도착점을 남기면 오래된 값이 되므로 남기지 않는다.
        let current = view.mapView.cameraPosition
        let alreadyThere = abs(current.target.lat - target.lat) < 1e-7
            && abs(current.target.lng - target.lng) < 1e-7
            && abs(current.zoom - zoom) < 1e-3
        pendingMoveTarget = alreadyThere ? nil : target
        pendingMoveZoom = alreadyThere ? nil : zoom
    }

    /// - Returns: 카메라를 옮겼는지. 손으로 지도를 옮기는 중이라 건너뛰었으면 `false`다.
    @discardableResult
    func moveToUserLocation(to coordinate: CLLocationCoordinate2D, zoomLevel: Double = 15) -> Bool {
        let coord = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        view.mapView.locationOverlay.location = coord
        // 처음 위치가 오기 전에 손으로 지도를 옮겼으면(옮기는 중이든 멈춘 뒤든) 카메라를 빼앗지 않는다.
        guard hasGestureSinceIdle == false, userMovedSinceProgrammaticMove == false else {
            showUserLocationOverlay()
            return false
        }
        enableUserTracking()

        let cameraPosition = NMFCameraPosition(coord, zoom: zoomLevel, tilt: 0, heading: 0)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        Self.applyMoveAnimation(to: cameraUpdate)
        startProgrammaticMove(to: coord, zoom: zoomLevel)
        view.mapView.moveCamera(cameraUpdate)
        return true
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

    /// 팝업 위치로 옮긴다. `bottomInset`을 주면 도착했을 때 지도를 가릴 높이(미리보기 카드 등)를 먼저 반영해,
    /// 옮긴 뒤에 다시 움직이지 않고 한 번에 보이는 영역 가운데로 간다.
    /// - Parameter zoomLevel: 옮긴 뒤의 줌. `nil`이면 지금 줌을 그대로 둔다(지도에서 마커를 누를 때).
    func moveCamera(to popup: Popup, topInset: CGFloat? = nil, bottomInset: CGFloat? = nil, zoomLevel: Double? = 15) {
        guard let lat = popup.latitude, let lng = popup.longitude else { return }
        disableUserTracking()
        if topInset != nil || bottomInset != nil {
            var visible = visibleInsets
            if let topInset { visible.top = max(0, topInset) }
            if let bottomInset { visible.bottom = max(0, bottomInset) }
            visibleInsets = visible
            // 화면에 보이는 지도는 그대로 두고 여백만 바꾼다(카메라 좌표만 새 영역 가운데로 옮겨지고 화면은 튀지 않는다).
            // 이어지는 팝업 이동이 한 번의 애니메이션으로 보이는 영역 가운데에 도착한다.
            isIssuingInsetMove = true
            view.mapView.setContentInset(mapInsets(for: visible), reason: Int32(NMFMapChangedByContentPadding))
            isIssuingInsetMove = false
            hasAppliedInsets = true
        }

        let target = NMGLatLng(lat: lat, lng: lng)
        let zoom = zoomLevel ?? view.mapView.zoomLevel
        let update = NMFCameraUpdate(scrollTo: target, zoomTo: zoom)
        Self.applyMoveAnimation(to: update)
        startProgrammaticMove(to: target, zoom: zoom)
        view.mapView.moveCamera(update)
    }

    /// 지도를 움직이는 애니메이션. 내 위치·팝업 위치로 옮길 때와 시트·카드에 맞춰 가운데를 옮길 때 모두 같은 움직임을 쓴다.
    /// 시트를 내린 상태에서 "목록 보기"를 눌렀을 때의 움직임(짧게 감속, 0.25초)에 맞췄다.
    static func applyMoveAnimation(to update: NMFCameraUpdate) {
        update.animation = .easeOut
        update.animationDuration = 0.25
    }

    /// 지도에서 검색창·칩(위)과 시트·미리보기 카드(아래)에 가리지 않고 보이는 영역을 정한다.
    /// 카메라 중심(마커를 고르거나 내 위치로 옮길 때의 기준점)이 이 영역의 가운데에 오도록 지도 여백(`contentInset`)으로 둔다.
    /// - Parameter recenter: 보고 있던 중심을 새 영역의 가운데로 옮길지. `false`면 카메라 좌표를 그대로 두고 여백만 바꾼다.
    ///   이때 그려진 지도가 여백 차이만큼 밀리므로, 시트를 끝까지 펼쳐 지도가 가려진 동안에만 쓴다.
    func setVisibleInsets(top: CGFloat, bottom: CGFloat, recenter: Bool = true) {
        let visible = UIEdgeInsets(top: max(0, top), left: 0, bottom: max(0, bottom), right: 0)
        let mapView = view.mapView
        let current = visibleInsets
        guard abs(current.top - visible.top) > 1 || abs(current.bottom - visible.bottom) > 1 else { return }
        visibleInsets = visible
        let insets = mapInsets(for: visible)
        defer { hasAppliedInsets = true }
        guard recenter else {
            // 카메라 좌표(리듀서가 아는 지도 중심)는 그대로 두고 여백만 바꾼다. 카메라 이벤트가 오지 않아 중심이 몰래 바뀌지 않는다.
            // 그려진 지도는 밀리지만 시트에 가려져 보이지 않고, 시트를 내리면 recenter로 다시 맞춘다.
            mapView.setContentInset(insets, keepCamera: true)
            return
        }
        // 코드 이동(내 위치, 팝업 선택)이 진행 중이면 중간 위치가 아니라 그 도착점을 새 영역 가운데로 둔다.
        // 이때는 원래 이동의 원인을 이어받아, 멈췄을 때 그 위치를 지도 중심 변경으로 알린다.
        let pendingTarget = pendingMoveTarget
        let target = pendingTarget ?? paddingReturnTarget ?? mapView.cameraPosition.target
        paddingReturnTarget = pendingTarget == nil ? target : nil
        // 여백만 바꾸면 카메라 좌표가 새 영역의 가운데로 옮겨지고(원인: 콘텐츠 패딩), 이어서 보던 중심으로 되돌린다.
        // 여백을 바꾸는 동안만 멈춤 알림을 무시한다. 이어지는 이동의 멈춤은 받아야 한다(처음처럼 바로 맞출 때 포함).
        isIssuingInsetMove = true
        mapView.setContentInset(insets, reason: Int32(NMFMapChangedByContentPadding))
        isIssuingInsetMove = false
        // 진행 중이던 이동이 있으면 그 줌까지 함께 이어 간다(중간 줌에서 멈추지 않게).
        let update = if let pendingTarget, let zoom = pendingMoveZoom {
            NMFCameraUpdate(scrollTo: pendingTarget, zoomTo: zoom)
        } else {
            NMFCameraUpdate(scrollTo: target)
        }
        update.reason = Int32(pendingTarget == nil ? NMFMapChangedByContentPadding : NMFMapChangedByDeveloper)
        // 처음 한 번은 화면을 그리는 중이라 움직임 없이 바로 맞춘다.
        if hasAppliedInsets {
            Self.applyMoveAnimation(to: update)
        }
        mapView.moveCamera(update)
    }

    func mapView(_ mapView: NMFMapView, cameraDidChangeByReason reason: Int, animated: Bool) {
        noteCameraChange(reason: reason)
    }

    private func noteCameraChange(reason: Int) {
        guard reason != NMFMapChangedByContentPadding else { return }
        hasMeaningfulChangeSinceIdle = true
        cameraChangedSinceMoveStart = true
        if reason == NMFMapChangedByGesture {
            userMovedSinceProgrammaticMove = true
            hasGestureSinceIdle = true
            paddingReturnTarget = nil
            // 손으로 움직이면 진행 중이던 코드 이동은 끝난 것으로 본다.
            pendingMoveTarget = nil
            pendingMoveZoom = nil
        }
    }

    func mapView(_ mapView: NMFMapView, cameraIsChangingByReason reason: Int) {
        noteCameraChange(reason: reason)
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
        // 여백을 바꾸는 도중의 멈춤은 무시한다. 이어지는 이동이 끝나면 다시 멈춤이 온다.
        guard isIssuingInsetMove == false else { return }
        // 여백 맞추기로 되돌아가는 이동이 끝났다.
        paddingReturnTarget = nil
        // 멈춤 사이에 보이는 영역 맞추기(콘텐츠 패딩)만 있었으면 사용자가 지도를 옮긴 것이 아니므로 알리지 않는다.
        // 손 제스처, 내 위치, 팝업 선택이 한 번이라도 있었으면 알린다.
        // 여백만 바뀐 멈춤이면 진행 중인 코드 이동의 도착점을 지우지 않는다(이어지는 이동이 그 도착점까지 가야 한다).
        guard hasMeaningfulChangeSinceIdle else { return }
        let byGesture = hasGestureSinceIdle
        hasMeaningfulChangeSinceIdle = false
        hasGestureSinceIdle = false
        // 코드 이동을 시작한 뒤 카메라가 실제로 움직였다가 멈췄을 때만 그 이동이 끝난 것으로 본다(도착했든, 위치 추적이 다른 곳에 세웠든).
        // 이동을 시작하기 전 제스처·이동의 멈춤이 늦게 와도 진행 중인 이동의 도착점을 지우지 않는다.
        if cameraChangedSinceMoveStart {
            pendingMoveTarget = nil
            pendingMoveZoom = nil
        }
        let center = mapView.cameraPosition.target
        DispatchQueue.main.async {
            self.onCenterChanged?(MapCoordinate(latitude: center.lat, longitude: center.lng), byGesture)
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
        // 아래 여백(탭바 높이) 바로 위에 붙인다.
        view.mapView.logoMargin = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 20)

        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: 37.5665, lng: 126.9780))
        Self.applyMoveAnimation(to: cameraUpdate)
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
    /// 지금 위치 권한 상태.
    var authorizationStatus: CLAuthorizationStatus { locationManager.authorizationStatus }
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
        // 처음 위치가 손으로 지도를 옮기는 중에 왔으면 카메라를 옮기지 않고, 다음 위치에서도 다시 옮기지 않는다.
        // 사용자가 직접 고른 위치를 뒤늦게 빼앗지 않는다(내 위치 버튼으로는 언제든 옮길 수 있다).
        publishLocation(location, moveCamera: hasMovedToUserLocation == false)
        hasMovedToUserLocation = true
        manager.stopUpdatingLocation()
    }

    private func emitCurrentLocationIfAvailable(moveCamera: Bool) {
        guard let location = locationManager.location else { return }
        publishLocation(location, moveCamera: moveCamera)
    }

    /// - Returns: 카메라를 내 위치로 옮겼는지.
    @discardableResult
    private func publishLocation(_ location: CLLocation, moveCamera: Bool) -> Bool {
        let coordinate = MapCoordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        DispatchQueue.main.async {
            self.onLocationUpdated?(coordinate)
        }

        // 카메라를 옮기지 않아도 위치 오버레이에는 넣어, 내 위치 버튼이 (0, 0)이라 반응하지 않는 일이 없게 한다.
        NaverMapCoordinator.shared.updateLocationOverlay(location.coordinate)
        guard moveCamera else { return false }
        return NaverMapCoordinator.shared.moveToUserLocation(to: location.coordinate)
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
        // 이름표가 없으면 그림이 색·모양만으로 정해지므로 이름을 키에 넣지 않는다.
        let cacheKey = (showsLabel ? "\(colorHex ?? "-")|\(style)|\(name)" : "\(colorHex ?? "-")|\(style)|-") as NSString
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
