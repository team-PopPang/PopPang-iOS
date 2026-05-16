//
//  TrendingCategoryChip.swift
//  PopPang
//
//  Created by 김동현 on 1/12/26.
//

import SwiftUI

struct TrendingCategoryChip: View {
    // let category: TrendingCategory
    let category: Recommend
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(category.recommendName)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(
                    isSelected ? Color.subWhite : Color.mainBlack
                )
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                // 배경
                .background(
                    Capsule()
                        .fill(
                            isSelected ? Color.mainOrange : Color.subWhite
                        )
                )
                // 스트로크
                .overlay(
                    Capsule()
                        .strokeBorder(
                            isSelected ? Color.clear : Color.mainGray6,
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain) // ❗️기본 버튼 스타일 제거 (중요)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
        .accessibilityLabel(category.recommendName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
