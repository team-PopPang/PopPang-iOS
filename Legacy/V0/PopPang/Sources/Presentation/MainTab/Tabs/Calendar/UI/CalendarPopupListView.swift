//
//  PopupListView.swift
//  PopPang
//
//  Created by 김동현 on 10/17/25.
//

import SwiftUI

struct CalendarPopupListView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    
    let userUuid: String
    let date: Date
    var body: some View {
        let popups = calendarViewModel.selectedPopups
        
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                
                Text(formattedDate(date))
                    .ppStyleFont(.scdream(.bold, size: 12))
                    .foregroundStyle(Color.mainBlack)
                
                Spacer()
                
                RegionButton(text: "지역") {
                    coordinator.presentSheet(.regionSheet(regions: calendarViewModel.regions,
                                                          selectedRegion: $calendarViewModel.selectedRegion,
                                                          selectedDistrict: $calendarViewModel.selectedDistrict,
                                                          onDismiss: {
                        Task {
                            await calendarViewModel.updatePersonalFilteredPopupList()
                        }
                    }))
                }
                .padding(.leading, -10)
                
                SortButton(selectedOption: $calendarViewModel.selectedOption) {
                    coordinator.presentSheet(.sortSheet(selectedOption: $calendarViewModel.selectedOption,
                                                        onDismiss: {
                        Task {
                            await calendarViewModel.updatePersonalFilteredPopupList()
                        }
                    }))
                }
                
            }
            .padding(.top, 20)
            
            if popups.isEmpty {
                Text("선택한 날짜에 팝업이 없습니다")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(popups.enumerated()), id: \.element.id) { index, popup in
                            CalendarPopupCell(popup: popup, isLiked: popup.isFavorited, onToggleLike: {
                                Task {
                                     await calendarViewModel.toggleLike(popup: popup)
                                }
                            })
                                .equatable()
                                .onTapGesture {
                                    coordinator.push(.popupDetail(userUuid, popup))
                                }
                            
                            // 마미막 셀 아래에는 Divider 넣지 않겠다
                            if index != popups.count - 1 {
                                Divider()
                                    .frame(height: 1)
                                    .background(Color.subWhite)
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ko_KR")
        dayFormatter.dateFormat = "d일 (E)"
        return dayFormatter.string(from: date)
    }
}

#Preview {
    CalendarPopupListView(userUuid: "1234", date: .now)
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>())
        .environmentObject(CalendarViewModel(userUuid: "1234"))
}
