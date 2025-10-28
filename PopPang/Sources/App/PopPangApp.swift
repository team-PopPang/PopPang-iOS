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
        }
    }
}
