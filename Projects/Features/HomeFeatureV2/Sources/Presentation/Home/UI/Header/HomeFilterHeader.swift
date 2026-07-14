//
//  HomeFilterHeader.swift
//  HomeFeature
//
//  Created by 김동현 on 6/15/26.
//

import SwiftUI
import ComposableArchitecture
import DSKit

struct HomeFilterHeader: View {
    let store: StoreOf<HomeFilter>
    let onRegionTap: () -> Void
    let onSortTap: () -> Void

    var body: some View {
        HStack {
            Text(store.selectedRegion?.region ?? "전체")
                .foregroundStyle(Color.mainBlack)
                .ppStyleFont(.scdream(.medium, size: 17))

            if let selectedDistrict = store.selectedDistrict, selectedDistrict != "전체" {
                Text(selectedDistrict)
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.medium, size: 17))
            }

            Spacer()

            RegionButton(text: "지역", action: onRegionTap)
                .padding(.leading, -10)
                .accessibilityIdentifier("home_region_dropdown")

            SortButton(selectedOption: .constant(store.selectedOption), action: onSortTap)
                .accessibilityIdentifier("home_sort_dropdown")
        }
    }
}

