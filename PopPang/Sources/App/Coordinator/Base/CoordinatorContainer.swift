//
//  CoordinatorContainer.swift
//  TestCoordinator
//
//  Created by 김동현 on 9/20/25.
//

import SwiftUI
import BottomSheet

struct CoordinatorContainer<Content: View>: View {
    @StateObject private var coordinator = Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>()
    @EnvironmentObject private var rootViewModel: RootViewModel

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
        
        // MARK: - BottomSheet
        .bottomSheet(
            // 시트 현재 위치
            bottomSheetPosition: $coordinator.bottomSheetPosition,
            
            // 사용자 드래그로 이동 가능한 위치 배열
            switchablePositions: coordinator.bottomSheet?.switchables ?? []) {
                // 시트 안에 어떤 뷰를 띄울지
                if let route = coordinator.bottomSheet {
                    coordinator.buildView(for: route)
                }
            }
            .ignoresSafeArea(edges: .top)
        
    }
}

