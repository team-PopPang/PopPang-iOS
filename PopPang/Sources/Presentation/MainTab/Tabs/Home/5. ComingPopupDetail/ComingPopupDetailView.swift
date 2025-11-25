//
//  ComingPopupDetailView.swift
//  PopPang
//
//  Created by 김동현 on 11/9/25.
//

import SwiftUI

struct ComingPopupDetailView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            GridPopupScrollView(homeViewModel: homeViewModel)
        }
        .padding(.horizontal, .contentPadding)
    }
}

private struct GridPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @ObservedObject var homeViewModel: HomeViewModel
    private let columns = [
        // flexible: 가로 공간이 남으면 균등하게 나눠 쓰기
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(homeViewModel.comingPopups) { popup in
                VStack(alignment: .leading) {
                    GridPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(homeViewModel.userUuid, popup))
                        }
                        .padding(.bottom, 0)
                }
            }
        }
    }
}

#Preview {
    ComingPopupDetailView()
}
