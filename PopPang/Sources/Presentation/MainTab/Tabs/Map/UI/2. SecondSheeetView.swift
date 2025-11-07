//
//  SecondSheeetView.swift
//  PopPang
//
//  Created by 김동현 on 11/7/25.
//

import SwiftUI

struct SecondSheeetView: View {
    @ObservedObject var mapViewModel: MapViewModel
    let onDismiss: () -> Void
    
    var body: some View {
        
        ScrollView {
            MapRegionSheet(
                regions: mapViewModel.regions,
                selectedRegion: $mapViewModel.selectedRegion,
                selectedDistrict: $mapViewModel.selectedDistrict
            ) {
                onDismiss()
            }
            .padding(.bottom, 100)
        }
        .ignoresSafeArea(edges: .top)
    }
}
