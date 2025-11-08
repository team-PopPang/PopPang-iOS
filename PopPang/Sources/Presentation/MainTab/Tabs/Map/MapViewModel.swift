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
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var mapPopups: [Popup] = []
    private var allPopups: [Popup] = [] // 전체 팝럽 저장용
    
    // MARK: - 맵 지역 시트 관련
    @Published var regions: [RegionList] = []
    @Published var selectedRegion: RegionList?
    @Published var selectedDistrict: String?
    
    // MARK: - 정렬 시트 관련
    @Published var selectedOption: MapSortButton.SortOption = .distance
    
    // MARK: - 로컬 검색 기능
    @Published var searchText: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        Task {
            await getAllPopupData()
        }
        bindDebounce()
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
}

// MARK: - 비동기 함수
extension MapViewModel {
    func getAllPopupData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.getRegionList() }
            group.addTask { await self.getPopupList() }
        }
        Logger.d("지도 데이터 로드 완료")
    }
    
    func getPopupList() async {
        do {
            let popups = try await popupUsecase.getPopupList()
            await MainActor.run {
                self.mapPopups = popups
                self.allPopups = popups
            }
        } catch {
            Logger.e("\(error)")
        }
    }
    
    func getRegionList() async {
        do {
            let regionListDTO = try await popupUsecase.getRegionList()
            await MainActor.run {
                self.regions = regionListDTO
                if let first = regionListDTO.first {
                    self.selectedRegion = first
                    self.selectedDistrict = first.districtList.first
                }
            }
        } catch {
            Logger.e("\(error)")
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


