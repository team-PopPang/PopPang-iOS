//
//  CalendarView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    private let segments: [String] = ["월간", "주간"]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 네비게이션바
            CustomNavigation()
                .padding(.top, 15)
                .padding(.horizontal, .contentPadding)
            
            // MARK: - 캘린더
            ScrollView {
                VStack {
                    CustomCalendar(popupList: calendarViewModel.calendarPopups)
                        .padding(.top, 24)
                    Spacer()
                }
                .padding(.horizontal, 10)
                
            }
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
                // coordinator.push(.alert)
            }
        }
        .frame(height: 45)
    }
}

#Preview {
    CalendarView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
}


/*
private struct MonthlyCalendarView: View {
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    var body: some View {
        ScrollView {
            VStack {
                CustomCalendar(popupList: calendarViewModel.calendarPopups)
                    .padding(.top, 24)
                Spacer()
            }
            .padding(.horizontal, 10)
        }
    }
}

private struct WeeklyCalendarView: View {
    var body: some View {
        VStack {
            
        }
    }
}
 */
