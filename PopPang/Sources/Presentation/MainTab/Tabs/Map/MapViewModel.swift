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
    
    init() {
        Task {
            do {
                let popups = try await popupUsecase.getPopupList()
                await MainActor.run {
                    self.mapPopups = popups
                }
            } catch {
                print("❌ MapViewModel getPopupList Error: \(error)")
            }
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
