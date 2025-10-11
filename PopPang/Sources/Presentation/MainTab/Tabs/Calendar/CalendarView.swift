//
//  CalendarView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    private let segments: [String] = ["월간", "주간"]
    
    var body: some View {
        VStack(spacing: 0) {
            
            CustomNavigation()
                .padding(.top, 15)
                .padding(.horizontal, .contentPadding)
                
            SegmentedControlView(segments: segments,
                                 views: [MonthlyCalendarView(), WeeklyCalendarView()],
                                 background: .mainGray3,
                                 foreground: .mainOrange,
                                 font: .scdream(.medium, size: 12))
            .padding(.top, 10)
            Spacer()
        }
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

private struct MonthlyCalendarView: View {
    var body: some View {
        VStack {
            
        }
    }
}

private struct WeeklyCalendarView: View {
    var body: some View {
        VStack {
            
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
}
