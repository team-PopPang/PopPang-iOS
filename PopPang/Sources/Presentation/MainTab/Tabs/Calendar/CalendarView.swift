//
//  CalendarView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @State private var searchText = ""
    var body: some View {
        VStack(spacing: 0) {
            
            CustomNavigation()
            Spacer()
            
            
        }
        .padding(.top, 15)
        .padding(.horizontal, .contentPadding)
    }
}

// MARK: - Custom Navigation
private struct CustomNavigation: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    var body: some View {
        HStack(spacing: 0) {
            Text("캘린더")
                .ppStyleFont(.scdream(.medium, size: 18))
            
            Spacer()
            
            IconButton {
                print("알림 버튼 클릭됨")
                coordinator.push(.alert)
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
}
