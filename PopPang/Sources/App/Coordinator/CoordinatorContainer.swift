//
//  CoordinatorContainer.swift
//  TestCoordinator
//
//  Created by 김동현 on 9/20/25.
//

import SwiftUI

struct CoordinatorContainer<Content: View>: View {
    @StateObject private var coordinator = Coordinator<MainRoute, SheetRoute>()
    let content: () -> Content
    
    var body: some View {
        NavigationStack(path: $coordinator.paths) {
            content()
                .navigationDestination(for: MainRoute.self) { route in
                    // MARK: - Route -> View 변환기(Route가 두종류)
                    coordinator.buildView(for: route)
                }
        }
        .environmentObject(coordinator)
        // 이 부분은 특정 뷰에서만 보이려면 주석처리하고, 특정 뷰에 달아준다
//        .sheet(item: $coordinator.sheet) { sheet in
//            coordinator.buildView(for: sheet)
//        }
    }
}

