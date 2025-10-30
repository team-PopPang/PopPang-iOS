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
                ForEach(Array(homeViewModel.gridPopups.prefix(3).enumerated()), id: \.element) { index, popup in
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
                GeometryReader { geo in
                    // MARK: - 이미지
                    KFImage(URL(string: popup.imageUrlList[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill) // 프레임을 채움
                        .frame(width: geo.size.width, height: geo.size.height)  // 포스트 사이즈
                        .clipped()                       // 넘치는 영역 제거
                }
                .frame(width: 106, height: 133)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                        .padding(.top, 10)
                    
                    Text(popup.name)
                        .font(.scdream(.bold, size: 15))
                        .foregroundStyle(Color.mainBlack)
                        .lineLimit(1) // 한줄만 표시
                        .truncationMode(.tail) // 넘치면 ...으로 표시
                        .padding(.top, 5)
                    
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

