//
//  AlertView.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct AlertView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @State private var selectedIndex = 0
    private let segments = ["활동", "키워드 설정"]
    
    var body: some View {
        VStack(spacing: 0) {

            // ✅ 세그먼트 헤더
            // SegmentHeader(segments: segments, selectedIndex: $selectedIndex)
            SegmentedControlView(segments: segments,
                                 views: [AView(),
                                  BView()],
                          background: .mainGray3,
                                 foreground: .mainOrange,
                                 font: .scdream(.medium, size: 12))
        }
        // toolbar
        .toolbar {
            // 커스텀 타이틀
            ToolbarItem(placement: .principal) {
                Text("알림")
                    .ppStyleFont(.scdream(.medium, size: 20))
                    .padding(.top, 10)
            }
            
            // 커스텀 우측
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    
                } label: {
                    Image("gear")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
        
}

#Preview {
    NavigationStack {
        AlertView()
            .environmentObject(HomeViewModel())
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
    }
}

struct AView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var homeViewModel: HomeViewModel
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

struct BView: View {
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
        }
    }
}

