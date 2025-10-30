//
//  MapViewModel.swift
//  PopPang
//
//  Created by 김동현 on 10/15/25.
//

import Foundation
import CoreLocation

final class MapViewModel: ObservableObject {
    @Dependency private var popupUsecase: PopupUsecaseProtocol
    @Published var mapPopups: [Popup] = []
    
    // MARK: - 맵 지역 시트 관련
    @Published var regions: [RegionList] = []
    @Published var selectedRegion: RegionList?
    @Published var selectedDistrict: String?
    
    init() {
        Task {
            await self.fetchPopupList()
            await self.fetchRegionList()
        }
    }
}

extension MapViewModel {
    func fetchPopupList() async {
        do {
            let popups = try await popupUsecase.getPopupList()
            await MainActor.run {
                self.mapPopups = popups
            }
            
            await self.fetchRegionList()
        } catch {
            print("❌ MapViewModel getPopupList Error: \(error)")
        }
    }
    func fetchRegionList() async {
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
            print("HomeViewModel.fetchRegionList(): ❌ 찜 목록 불러오기 오류: \(error)")
        }
    }
}

final class LocationPermissionManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationPermissionManager()
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
            print("✅ 위치 권한 허용됨")
        case .denied, .restricted:
            print("❌ 위치 권한 거부됨")
        case .notDetermined:
            print("🕒 아직 권한 선택 전")
        @unknown default:
            break
        }
    }
}
