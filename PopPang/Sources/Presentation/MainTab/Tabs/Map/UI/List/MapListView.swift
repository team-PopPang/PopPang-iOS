//
//  MapListView.swift
//  PopPang
//
//  Created by 김동현 on 10/23/25.
//

import SwiftUI
import BottomSheet

struct MapListView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    let popups: [Popup]
    @Binding var firstSheetPosition: BottomSheetPosition
    // let firstSheetPosition: BottomSheetPosition
    
    var body: some View {
        if popups.isEmpty {
            Text("검색 결과가 없습니다.")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 24)
        } else {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 10) {
                    ForEach(Array(popups.enumerated()), id: \.element) { index, popup in
                        MapListPopupCell(popup: popup)
                            .onTapGesture {
       
                                // 시트가 없을때 제외하고는 항상 -300
                                if firstSheetPosition == .absolute(0)  {
                                    MapCoordinator.shared.moveCamera(to: popup)
                                } else {
                                    MapCoordinator.shared.moveCamera(to: popup, yOffset: -300)
                                }
                                
                          
                                // 동일 위경도일때 시트 누른 마커 최상단
                                MapCoordinator.shared.focusMarker(identifier: index)
                                
                                // 시트를 절반으로
                                if firstSheetPosition !=  .relative(0.5) {
                                    firstSheetPosition = .relative(0.5)
                                }
                            }
                        
                        if index != popups.count - 1 {
                            Divider()
                                .frame(height: 1)
                                .background(Color.subWhite)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 133)
            }
            .frame(maxWidth: .infinity) 
            .padding(.top, 20)
        }
    }
}
