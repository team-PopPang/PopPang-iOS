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

                Spacer()
                
                MapSortButton(selectedOption: $mapViewModel.selectedOption) {
                    onSortTap()
                }
            }
            
            // view
            MapListView(popups: mapViewModel.mapPopups)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.horizontal, .contentPadding)
    }
}
