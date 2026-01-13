//
//  TrendingCategoryScrollView.swift
//  PopPang
//
//  Created by 김동현 on 1/12/26.
//

import SwiftUI

struct TrendingCategoryScrollView: View {
    @ObservedObject var mapViewModel: MapViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(mapViewModel.categories) { category in
                    TrendingCategoryChip(
                        category: category,
                        isSelected: mapViewModel.selectedCategoryId == category.id,
                    ) {
                        mapViewModel.selectCategory(category)
                    }
                }
            }
        }
    }
}

