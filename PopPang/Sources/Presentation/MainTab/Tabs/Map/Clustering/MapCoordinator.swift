//
//  MapCoordinator.swift
//  PopPang
//
//  Created by 김동현 on 10/30/25.
//

import SwiftUI
import NMapsMap

final class MapCoordinator: NSObject,
                            ObservableObject,
                            CLLocationManagerDelegate,
                            NMFMapViewCameraDelegate {
    
    static let shared = MapCoordinator()
    let view = NMFNaverMapView(frame: .zero)
    var locationManager: CLLocationManager?
    var popups: [Popup] = []
    var clusterer: NMCClusterer<ItemKey>?
    var onMarkerSelected: ((ItemKey, Popup) -> Void)?

    override init() {
        super.init()
        setupMap()

        // ✅ 마커 표시
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.makeClusterer()
            self.moveToUserLocation()
        }
    }

    // MARK: - 지도 기본 설정
    /// 지도 초기 상태를 설정합니다.
    /// - 줌 레벨, 최소/최대 줌, 모드(positionMode), 초기 카메라 위치 등을 지정
    private func setupMap() {
        view.mapView.addCameraDelegate(delegate: self)
        
        view.mapView.zoomLevel = 10
        view.mapView.minZoomLevel = 5
        view.mapView.maxZoomLevel = 20
        view.mapView.positionMode = .direction
        
        view.mapView.isNightModeEnabled = false
        view.showLocationButton = false           // 디폴트 내위치 이동 버튼 비활성화
        view.showZoomControls = false             // 줌 확대, 축소 버튼 비활성화
        view.showCompass = true                   // 지도 회전시 나침반 활성화
        view.showScaleBar = false                 // 우측 하단 축적바 비활성화
        
        // 로고 위치 조정
        view.mapView.logoAlign = .leftBottom
        view.mapView.logoMargin = UIEdgeInsets(top: 0, left: 20, bottom: 20, right: 0)

        // 서울 시청 기준
        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: 37.5665, lng: 126.9780))
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }

    // MARK: - 지도 반환
    /// UIViewRepresentable에서 실제 네이버 지도를 가져갈 수 있도록 반환
    func getNaverMapView() -> NMFNaverMapView {
        return view
    }
    
    
    // MARK: - 위치 권한 요청
    /// 위치 서비스가 켜져 있는지 확인 후,
    /// CLLocationManager를 초기화하여 위치 추적을 시작할 수 있도록 준비
    func checkIfLocationServiceIsEnabled() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                DispatchQueue.main.async {
                    self.locationManager = CLLocationManager()
                    self.locationManager!.delegate = self
                    
                    // 정확도 향상 하지만 실시간 고정밀 위치 추적이라 위치 업데이트 빈번 벌생
                    self.locationManager!.desiredAccuracy = kCLLocationAccuracyBest
                    
                    // UI 업데이트 줄이기 위해 최소 30m이동시만 업데이트
                    // self.locationManager!.desiredAccuracy = kCLLocationAccuracyHundredMeters
                    // self.locationManager!.distanceFilter = 30
                }
            } else {
                print("⚠️ 위치 서비스가 꺼져 있습니다.")
            }
        }
    }
    
    // MARK: - 사용자 위치로 이동
    /// 현재 사용자의 위치로 카메라를 이동
    /// 위치 오버레이의 좌표를 기반으로 이동
    func moveToUserLocation(zoomLevel: Double = 15) {
        
        // 위치 이동 + 줌 레벨 복구
        let coord = view.mapView.locationOverlay.location
        let cameraPosition = NMFCameraPosition(coord, zoom: zoomLevel, tilt: 0, heading: 0)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }
    
    // MARK: - 권한이 나중에 추가되었을 때 내 위치로 이동
    /// 외부에서 전달받은 실제 좌표로 카메라 이동
    func moveToUserLocation(to coordinate: CLLocationCoordinate2D, zoomLevel: Double = 15) {
        let coord = NMGLatLng(lat: coordinate.latitude, lng: coordinate.longitude)
        
        // ✅ 네이버맵 오버레이(파란 점) 위치도 같이 갱신
        view.mapView.locationOverlay.location = coord
        
        let cameraPosition = NMFCameraPosition(coord, zoom: zoomLevel, tilt: 0, heading: 0)
        let cameraUpdate = NMFCameraUpdate(position: cameraPosition)
        cameraUpdate.animation = .easeIn
        view.mapView.moveCamera(cameraUpdate)
    }
    
    // MARK: - 권한이 나중에 추가되었을 때 내 위치 마커 표시
    func enableUserLocationOverlay() {
        view.mapView.positionMode = .direction  // 내 위치 표시 모드
        view.mapView.locationOverlay.hidden = false
    }
}

// MARK: - 클러스터 관련
extension MapCoordinator {
    
    // MARK: 클러스터 생성
    /// 지도 위의 Spot 배열을 기반으로 클러스터를 생성합니다.
    /// - minZoom: 멀리서도 묶임이 시작되는 줌 레벨
    /// - maxZoom: 이 줌 이상에서는 클러스터가 풀리고 개별 마커로 전환됨
    /// - screenDistance: 마커가 얼마나 가까이 있을 때 클러스터로 묶일지 (픽셀 단위)
    private func makeClusterer() {
        
        // 기존 클러스터 제거
        self.clusterer?.clear()
        self.clusterer = nil
        
        let builder = NMCBuilder<ItemKey>()
        
        // 커스텀 리프 마커 등록 (사각형이나 파란색 심볼 등)
        let leafUpdater = LeafMarkerUpdater()
        leafUpdater.onMarkerSelected = { [weak self] key in
            guard let self = self else { return }
            if key.identifier < self.popups.count {
                let selectedPopup = self.popups[key.identifier]
                self.onMarkerSelected?(key, selectedPopup)
            }
        }
        builder.leafMarkerUpdater = leafUpdater
        
        // 클러스터 마커도 필요하면 등록
        let clusterUpdater = ClusterMarkerUpdater()
        builder.clusterMarkerUpdater = clusterUpdater
        
        // 클러스터 동작 범위
        // builder.minZoom = 10            // 멀리서도 묶임 시작(필요시 조정)
        // builder.maxZoom = 12           // 이 줌 이상이면 바로 분리(값 낮출수록 빨리 풀림)
        // builder.screenDistance = 40.0  // 마커 간 거리 기준(px). 작을수록 빨리 분리됨
        
        builder.minZoom = 5           // 전국 축소에도 클러스터 작동
        builder.maxZoom = 12          // 완전히 확대하면 분리
        
        self.clusterer = builder.build()
        
        // Spot을 ItemKey로 변환하여 클러스터에 추가
        var keyTagMap: [ItemKey: NSObject] = [:]
        for (index, popup) in popups.enumerated() {
            let key = ItemKey(identifier: index,
                              position: NMGLatLng(lat: popup.latitude ?? 0, lng: popup.longitude ?? 0), imageURL: popup.imageUrlList[0])
            keyTagMap[key] = NSNull()
        }
        clusterer?.addAll(keyTagMap)
        clusterer?.mapView = self.view.mapView
    }
    
    
    // MARK: Spot 데이터 갱신
    /// ViewModel에서 Spot 배열이 변경될 때마다 호출됨
    /// 새로운 Spot 데이터로 클러스터를 다시 생성
    func updateSpots(_ newPopups: [Popup]) {
        
        // 값이 같으면 갱신 안함
        guard newPopups != popups else { return }
        
        // 갱신
        self.popups = newPopups
        // makeClusterer()
        

        // MARK: - 최적화
        // 기존 클러스터 초기화 없이, 변경분만 반영
        clusterer?.clear()
        var keyTagMap: [ItemKey: NSObject] = [:]
        for (index, popup) in newPopups.enumerated() {
            let key = ItemKey(identifier: index,
                              position: NMGLatLng(lat: popup.latitude ?? 0,
                                                  lng: popup.longitude ?? 0),
                              imageURL: popup.imageUrlList[0])
            keyTagMap[key] = NSNull()
        }
        clusterer?.addAll(keyTagMap)
    }
    
    func mapViewCameraIdle(_ mapView: NMFMapView) {
         let zoom = mapView.zoomLevel
        Logger.d("📸 현재 줌 레벨: \(zoom)")
    }
}

// MARK: - 카메라 이동
extension MapCoordinator {
    func moveCamera(to popup: Popup, zoomLevel: Double = 15) {
        guard let lat = popup.latitude, let lng = popup.longitude else { return }
        
        let coord = NMGLatLng(lat: lat, lng: lng)
        let update = NMFCameraUpdate(scrollTo: coord,
                                     zoomTo: zoomLevel)
        
        
        update.animation = .easeIn
        view.mapView.moveCamera(update)
    }
}
