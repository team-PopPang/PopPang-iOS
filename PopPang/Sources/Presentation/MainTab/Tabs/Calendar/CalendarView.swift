//
//  CalendarView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import Kingfisher

struct CalendarView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    @EnvironmentObject private var rootViewModel: RootViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            
            // MARK: - 네비게이션바
            CustomNavigationBar {
                Text("캘린더")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)
                
                Spacer()
                
                IconButton {
                    coordinator.push(.alert(uuid: rootViewModel.user?.userUuid ?? ""))
                }
            }
            
            // MARK: - 캘린더 & 시트
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // MARK: - 캘린더
                    CustomCalendar(
                        eventCounts: calendarViewModel.popupEventCounts,
                        onDateSelected: { date in
                            calendarViewModel.selectDate(date)
                        }
                    )
                    .padding(.top, 24)
                    .padding(.horizontal, 15)
                    
                    // MARK: - 시트
                    CalendarPopupListView(
                        userUuid: calendarViewModel.userUuid,
                        date: calendarViewModel.selectedDate
                    )
                    .padding(.horizontal, 15)
                    
                    // MARK: - 그림자 시트 디자인
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .mask(
                                // 위쪽 70%만 유지시키고 아래 30%는 잘라버림
                                LinearGradient(
                                    gradient: Gradient(colors: [.black, .clear, .clear, .clear]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .applyShadow(
                                color: .black,
                                alpha: 0.05,
                                x: 0,
                                y: -4,
                                blur: 8
                            )
                    )
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .padding(.top, 10)
            Spacer()
        }
        .onAppear {
            Task {
                await calendarViewModel.getAllPopupData()
            }
        }
    }
}

#Preview {
    CalendarView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>())
        .environmentObject(CalendarViewModel(userUuid: "1234"))
}
