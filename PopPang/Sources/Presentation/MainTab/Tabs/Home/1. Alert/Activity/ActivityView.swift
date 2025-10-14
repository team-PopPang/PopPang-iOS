//
//  ActivityView.swift
//  PopPang
//
//  Created by 김동현 on 10/13/25.
//

import SwiftUI

struct ActivityView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @ObservedObject var activityViewModel: ActivityViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(Array(homeViewModel.gridPopups.enumerated()), id: \.element) { index, popup in
                    AlertPopupCell(popup: popup)
                        .contentShape(Rectangle()) // 터치 영역을 셀 전체로 확장
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
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

private struct AlertPopupCell: View {
    let popup: Popup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image("\(popup.imageURL)")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.address.shortAddress)
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                    
                    Text(popup.name)
                        .ppStyleFont(.scdream(.medium, size: 15))
                        .foregroundStyle(Color.mainBlack)
                    
                    HStack {
                        Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                        Text("-")
                        Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                    }
                    .ppStyleFont(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray)
                    
                    Spacer()
                }
                .padding(.leading, 18)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        // .background(.blue)
        .padding(.vertical, 15)
    }
}

#Preview {
    ActivityView(activityViewModel: ActivityViewModel(userUuid: "1234"))
}

final class ActivityViewModel: ObservableObject {
    let userUuid: String
    init(userUuid: String) {
        self.userUuid = userUuid
    }
}
