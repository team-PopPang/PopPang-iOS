//
//  PopPangApp.swift
//  PopPang
//
//  Created by 김동현 on 9/6/25.
//

import SwiftUI
import Kingfisher

@main
struct PopPangApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    @StateObject private var rootViewModel: RootViewModel
    
    // MARK: - 버전 업데이트 관련 상태
    @State private var showUpdateAlert = false
    @State private var latestVersion: String?
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        
        // 1. 의존성 등록
        DIContainer.config(isStub: false)
        
        // 2. RootViewModel 생성
        _rootViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createRoot())
        
        // 3. 탭바/네비게이션바 커스텀
        UITabBar.configureAppearance()
        UINavigationBar.configureAppearance()
        
        // 4. 이미지 캐싱
        // 메모리 캐시 최대 용량 제한 (예: 50MB)
        ImageCache.default.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024
        ImageCache.default.memoryStorage.config.countLimit = 200 // 최대 개수 제한

        // 디스크 캐시도 원한다면
        ImageCache.default.diskStorage.config.sizeLimit = 200 * 1024 * 1024
    }
    
    var body: some Scene {
        WindowGroup {
            RootViewSwitcher(rootViewModel: rootViewModel)
                .alert(isPresented: $showUpdateAlert) {
                    Alert(
                        title: Text("앱 업데이트 필요"),
                        message: Text("새로운 기능과 성능 개선을 위해 최신 버전 (\(latestVersion ?? ""))을 사용해 보세요!"),
                        dismissButton: .default(Text("업데이트")) {
                            if let url = URL(string: "https://apps.apple.com/app/id6753014613") {
                                UIApplication.shared.open(url)
                            }
                        }
                    )
                }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                checkForAppUpdates()   // 앱이 포그라운드로 돌아올 때 체크
            }
        }
    }
}

extension PopPangApp {
    
    // 최신 버전 확인 로직
    func checkForAppUpdates() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        
        fetchLatestVersionFromAppStore { latest in
            guard let latest = latest else { return }

            if isUpdateRequired(currentVersion: currentVersion, latestVersion: latest) {
                self.latestVersion = latest
                self.showUpdateAlert = true
            }
        }
    }

    // iTunes API에서 최신 버전 가져오기
    func fetchLatestVersionFromAppStore(completion: @escaping (String?) -> Void) {
        
        guard let url = URL(string: "https://itunes.apple.com/lookup?id=6753014613&country=KR&timestamp=\(Int(Date().timeIntervalSince1970))") else {
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data else {
                completion(nil)
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let results = json["results"] as? [[String: Any]],
                   let latestVersion = results.first?["version"] as? String {
                    completion(latestVersion)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        .resume()
    }

    // 버전 비교 로직
    func isUpdateRequired(currentVersion: String, latestVersion: String) -> Bool {
        return currentVersion.compare(latestVersion, options: .numeric) == .orderedAscending
    }
}
