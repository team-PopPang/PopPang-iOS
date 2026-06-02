//
//  FirstSheetView.swift
//  PopPang
//
//  Created by 김동현 on 11/7/25.
//

import SwiftUI
import BottomSheet

struct FirstSheetView: View {
    @ObservedObject var mapViewModel: MapViewModel
    @Binding var firstSheetPosition: BottomSheetPosition
    let onBackgroundTap: (Popup) -> Void
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
            .padding(.horizontal, .contentPadding)
            
            // view
            MapListView(popups: mapViewModel.mapPopups, firstSheetPosition: $firstSheetPosition) { popup in
                onBackgroundTap(popup)
            }
                .padding(.horizontal, .contentPadding)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
