//
//  MapListView.swift
//  PopPang
//
//  Created by 김동현 on 10/23/25.
//

import SwiftUI

struct MapListView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    let popups: [Popup]
    
    var body: some View {
        if popups.isEmpty {
            Text("팝업 데이터 수집중")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        } else {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(Array(popups.enumerated()), id: \.element) { index, popup in
                        MapListPopupCell(popup: popup)
                            .onTapGesture {
                                coordinator.push(.popupDetail(popup)) // ✅ 디테일 화면 이동
                            }
                        
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
