//
//  MapViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/15/25.
//

import Foundation
import CoreLocation
import Combine

final class MapViewModel: ObservableObject {
    let userUuid: String
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var mapPopups: [Popup] = []
    private var allPopups: [Popup] = [] // 전체 팝럽 저장용
    
    // MARK: - 맵 지역 시트 관련
    @Published var regions: [RegionList] = []
    @Published var selectedRegion: RegionList?
    @Published var selectedDistrict: String?
    
    // MARK: - 정렬 시트 관련
    @Published var selectedOption: MapSortButton.SortOption = .closest
    
    // MARK: - 로컬 검색 기능
    @Published var searchText: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 지도 화면 중심 좌표 구독
    @Published var mapCenter: CLLocationCoordinate2D?
    
    init(userUuid: String) {
        self.userUuid = userUuid
        observeMapCenter()
        bindDebounce()
        Task {
            await getAllPopupData()
        }
    }
    
    // 검색 디바운스 바인딩
    private func bindDebounce() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self else { return }
                self.filterPopups(text: text)
            }
            .store(in: &cancellables)
    }
    
    // 필터링 로직
    private func filterPopups(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            mapPopups = allPopups
            return
        }
        
        let lowercased = trimmed.lowercased()
        let filtered = allPopups.filter {
            $0.name.lowercased().contains(lowercased) ||
            ($0.address.lowercased().contains(lowercased))
        }
        
        mapPopups = filtered
    }
    
    // 네이버 카메라 이동 후 중심 좌표 업데이트 값 구독
    private func observeMapCenter() {
        MapCoordinator.shared.$centerCoordinate
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] mapCenter in
                guard let self = self else { return }
                self.mapCenter = mapCenter
            }
            .store(in: &cancellables)
    }
}

// MARK: - 비동기 함수
extension MapViewModel {
    func getAllPopupData() async {
        // MARK: - 지역 리스트는 리턴값이 다르므로 async let으로 병렬 실행(존재하지 않을때만 호출)
        if regions.isEmpty {
            async let regionTask = self.getRegionList()
            let regionList = await regionTask
            await MainActor.run {
                self.regions = regionList
                if let first = regionList.first {
                    self.selectedRegion = first
                    self.selectedDistrict = first.districtList.first
                }
            }
        }
        
        async let getMapPopupListTask = self.getPersonamMapFilteredPopupList()
        let popups = await getMapPopupListTask
        await MainActor.run {
            self.mapPopups = popups
            self.allPopups = popups
        }
        Logger.d("지도 데이터 로드 완료")
    }
    
    func getPersonamMapFilteredPopupList() async -> [Popup] {
        do {
            let popups = try await popupUsecase.getPersonalMapFilteredPopupList(userUuid: userUuid,
                                                                                region: selectedRegion?.region ?? "전체",
                                                                                district: selectedDistrict ?? "전체",
                                                                                latitude: nil,
                                                                                longitude: nil,
                                                                                mapSortStandard: selectedOption.rawValue)
            return popups
        } catch {
            Logger.e("\(error)")
            return []
        }
    }
    
    func updatePersonamMapFilteredPopupList() async {
        do {
            let popups = try await popupUsecase.getPersonalMapFilteredPopupList(userUuid: userUuid,
                                                                                region: selectedRegion?.region ?? "전체",
                                                                                district: selectedDistrict ?? "전체",
                                                                                latitude: mapCenter?.latitude,
                                                                                longitude: mapCenter?.longitude,
                                                                                mapSortStandard: selectedOption.rawValue)
            await MainActor.run {
                self.mapPopups = popups
            }
        } catch {
            Logger.e("\(error)")
        }
    }
    
    func getRegionList() async -> [RegionList] {
        do {
            let regionList = try await popupUsecase.getRegionList()
                .sorted { lhs, rhs in
                    // 전체를 1순위 서울을 2순위
                    if lhs.region == "전체" { return true }
                    if rhs.region == "전체" { return false }
                    if lhs.region == "서울" { return true }
                    if rhs.region == "서울" { return false }
                    return false
                }
            return regionList
        } catch {
            Logger.e("\(error)")
            return []
        }
    }
}


// MARK: - LocationManager
final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()
    private var hasMovedToUserLocation = false   // 최초 1회만 이동시키기
    
    private override init() {
        super.init()
        locationManager.delegate = self
    }
    
    // 위치권한 및 상태 관리 클래스
    // 권한 요청, 권한 상태감지, 위치 업데이트 가능
    private let locationManager = CLLocationManager()
    
    // 권한 요청
    func requestPermission() {
        // ✅ 권한 요청
        locationManager.requestWhenInUseAuthorization()
        
        // 만약 백그라운드까지 필요하다면:
        // locationManager.requestAlwaysAuthorization()
    }
    
    // 권한 변경 감지
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            Logger.d("위치 권한 허용됨")
            locationManager.startUpdatingLocation()
            MapCoordinator.shared.enableUserLocationOverlay()
            
        case .denied, .restricted:
            Logger.e("위치 권한 거부됨")
            DispatchQueue.main.async {
                AlertManager.shared.showLocationPermissionAlert()
            }
        case .notDetermined:
            Logger.w("🕒 아직 권한 선택 전")
        @unknown default:
            break
        }
    }
    
    // GPS에서 내 위치를 받으면 지도 카메라를 한번만 내 위치로 이동
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // 앱 켰을 때 딱 한 번만 내 위치로 이동
        if !hasMovedToUserLocation {
            hasMovedToUserLocation = true
            MapCoordinator.shared.moveToUserLocation(to: location.coordinate)
        }
    }
}


