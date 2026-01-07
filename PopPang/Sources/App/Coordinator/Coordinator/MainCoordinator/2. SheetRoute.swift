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
        selectedDistrict: Binding<String?>,
        onDismiss: (() -> Void)? = nil
    )
    
    case sortSheet(
        selectedOption: Binding<SortButton.SortOption>,
        onDismiss: (() -> Void)? = nil
    )
    
    case reviewSheet
}

extension Coordinator where R == SheetRoute {
    @ViewBuilder
    func buildView(for route: R) -> some View {
        switch route {
        case .regionSheet(let regions, let selectedRegion, let selectedDistrict, let onDismiss):
            RegionButtonSheet(regions: regions,
                              selectedRegion: selectedRegion,
                              selectedDistrict: selectedDistrict)
                             .presentationDetents([.fraction(0.4)])
                             .onDisappear {
                                 onDismiss?()
                             }
            
        case .sortSheet(let selectedOption, let onDismiss):
            SortButtonSheet(selectedOption: selectedOption)
                .presentationDetents([.fraction(0.4)])
                .onDisappear {
                    onDismiss?()
                }
            
        case .reviewSheet:
            ReviewWriteSheet()
                .presentationDetents([.fraction(0.4)])
        }
    }
}
