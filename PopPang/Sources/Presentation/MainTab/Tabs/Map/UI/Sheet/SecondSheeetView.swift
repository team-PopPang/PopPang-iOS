//
//  SecondSheeetView.swift
//  PopPang
//
//  Created by 김동현 on 11/7/25.
//

import SwiftUI

enum SecondSheetType {
    case region
    case sort
    case none
}

struct SecondSheeetView: View {
    @ObservedObject var mapViewModel: MapViewModel
    let type: SecondSheetType
    let onDismiss: () -> Void
    
    var body: some View {
        
        ScrollView {
            switch type {
            case .region:
                MapRegionSheet(
                    regions: mapViewModel.regions,
                    selectedRegion: $mapViewModel.selectedRegion,
                    selectedDistrict: $mapViewModel.selectedDistrict
                ) {
                    if let region = mapViewModel.selectedRegion?.region,
                       let district = mapViewModel.selectedDistrict {
                        Logger.d("선택된 지역: \(region), 구: \(district)")
                    }
                    onDismiss()
                }
                .padding(.bottom, 100)
            case .sort:
                MapSortButtonSheet(selectedOption: $mapViewModel.selectedOption) {
                    Logger.d("선택된 정렬: \(mapViewModel.selectedOption)")
                    onDismiss()
                }
                .padding(.bottom, 100)
            case .none:
                EmptyView()
            }
        }
        .ignoresSafeArea(edges: .top)
    }
}
