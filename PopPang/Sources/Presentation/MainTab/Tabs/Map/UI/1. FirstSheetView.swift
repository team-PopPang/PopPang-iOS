//
//  FirstSheetView.swift
//  PopPang
//
//  Created by 김동현 on 11/7/25.
//

import SwiftUI

struct FirstSheetView: View {
    @ObservedObject var mapViewModel: MapViewModel
    let onButtonTap: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            // button
            HStack {
                MapRegionButton(text: mapViewModel.selectedRegion?.region ?? "전체") {
                    print("버튼눌림")
                    onButtonTap()
                }
                Spacer()
            }
            .padding(.leading, -10)
            
            // view
            MapListView(popups: mapViewModel.mapPopups)
        }
        .padding(.horizontal, .contentPadding)
    }
}
