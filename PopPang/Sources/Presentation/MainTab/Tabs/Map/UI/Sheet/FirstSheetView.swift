//
//  FirstSheetView.swift
//  PopPang
//
//  Created by 김동현 on 11/7/25.
//

import SwiftUI

struct FirstSheetView: View {
    @ObservedObject var mapViewModel: MapViewModel
    let onRegionTap: () -> Void
    let onSortTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // button
            HStack {
                Text(mapViewModel.selectedRegion?.region ?? "전체")
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.medium, size: 17))
                
                Spacer()
                
                MapRegionButton(text: "지역") {
                    print("버튼눌림")
                    onRegionTap()
                }
                
                MapSortButton(selectedOption: $mapViewModel.selectedOption) {
                    onSortTap()
                }
            }
            
            // view
            MapListView(popups: mapViewModel.mapPopups)
        }
        .padding(.horizontal, .contentPadding)
    }
}
