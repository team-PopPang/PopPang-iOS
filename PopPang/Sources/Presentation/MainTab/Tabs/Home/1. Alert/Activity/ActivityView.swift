//
//  ActivityView.swift
//  PopPang
//
//  Created by 김동현 on 10/13/25.
//

import SwiftUI
import Kingfisher

struct ActivityView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @ObservedObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(activityViewModel.avtivityPopupList.prefix(50).enumerated()), id: \.element) { index, popup in
                    
                    HStack {
                        AlertPopupCell(popup: popup)
                            .contentShape(Rectangle()) // 터치 영역을 셀 전체로 확장
                            .onTapGesture {
                                coordinator.push(.popupDetail(popup))
                            }
                        
                        if activityViewModel.isEditing {
                            Button {
                                activityViewModel.checkBoxTapped(popup: popup)
                            } label: {
                                Image(systemName: activityViewModel.selectedPopupIds.contains(popup.popupUuid) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(Color.mainOrange)
                            }
                        }
                    }
                    
                    // 마지막 셀 아래에는 Divider 넣지 않겠다
                    if index != homeViewModel.gridPopups.count - 1 {
                        Divider()
                            .frame(height: 1)
                            .background(Color.subWhite)
                    }
                }
            }
        }
        .padding(.horizontal, .contentPadding)
    }
}

#Preview {
    ActivityView(activityViewModel: ActivityViewModel(userUuid: "1234"))
}

