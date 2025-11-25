//
//  CoordinatorContainer.swift
//  TestCoordinator
//
//  Created by 김동현 on 9/20/25.
//

import SwiftUI

struct CoordinatorContainer<Content: View>: View {
    @StateObject private var coordinator = Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>()

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
        
        // MARK: - Overlay
        .overlay {
            if let overlay = coordinator.overlay {
                coordinator.buildView(for: overlay)
            }
        }
        
        // MARK: - Sheet
        .sheet(item: $coordinator.sheet) { item in
            coordinator.buildView(for: item)
                // .presentationDetents(item.detents)
                // .presentationDragIndicator(item.showIndicator ? .visible : .hidden)
        }
    }
}
