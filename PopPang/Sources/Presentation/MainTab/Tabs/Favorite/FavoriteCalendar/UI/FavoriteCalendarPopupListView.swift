//
//  FavoritePopupListView.swift
//  PopPang
//
//  Created by 김동현 on 11/8/25.
//

import SwiftUI

struct FavoriteCalendarPopupListView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    let date: Date
    let popups: [Popup]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            HStack {
                Text(formattedDate(date))
                    .ppStyleFont(.scdream(.bold, size: 12))
                    .foregroundStyle(Color.mainBlack)
                Spacer()
            }
            .padding(.top, 20)
            
            if popups.isEmpty {
                Text("선택한 날짜에 팝업이 없습니다")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(popups.enumerated()), id: \.element) { index, popup in
                            FavoriteCalendarPopupCell(popup: popup)
                                .onTapGesture {
                                    coordinator.push(.popupDetail(favoriteViewModel.userUuid, popup))
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
