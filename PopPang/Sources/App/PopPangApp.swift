//
//  PopPangApp.swift
//  PopPang
//
//  Created by 김동현 on 9/6/25.
//

import SwiftUI

@main
struct PopPangApp: App {
    @StateObject private var rootViewModel: RootViewModel
    
    init() {
        // 1. 의존성 등록
        DIContainer.config()
        
        // 2. RootViewModel 생성
        _rootViewModel = StateObject(wrappedValue: ViewModelFactory.shared.createRoot())
    }
    
    var body: some Scene {
        WindowGroup {
            RootViewSwitcher(rootViewModel: rootViewModel)
        }
    }
}
