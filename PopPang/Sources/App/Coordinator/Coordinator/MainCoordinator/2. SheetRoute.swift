//
//  SheetRoute.swift
//  PopPang
//
//  Created by 김동현 on 11/25/25.
//

import SwiftUI

enum SheetRoute: Identifiable {
    var id: String { String(describing: self) }
    
    case regionSheet(
        regions: [RegionList],
        selectedRegion: Binding<RegionList?>,
        selectedDistrict: Binding<String?>
    )
    case sortSheet(
        selectedOption: Binding<SortButton.SortOption>
    )
}

extension Coordinator where R == SheetRoute {
    @ViewBuilder
    func buildView(for route: R) -> some View {
        switch route {
        case .regionSheet(let regions, let selectedRegion, let selectedDistrict):
            RegionButtonSheet(regions: regions,
                              selectedRegion: selectedRegion,
                              selectedDistrict: selectedDistrict)
                             .presentationDetents([.fraction(0.4)])
            
        case .sortSheet(let selectedOption):
            SortButtonSheet(selectedOption: selectedOption)
                .presentationDetents([.fraction(0.4)])
        }
    }
}
