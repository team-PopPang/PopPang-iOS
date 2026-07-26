//
//  HomeTopAnchorButton.swift
//  HomeFeatureV2
//
//  Created by 김동현 on 7/14/26.
//

import SwiftUI
import DSKit

struct HomeTopAnchorButton: View {
    let isVisible: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            DSKitResource.image("TopAnchor")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .foregroundStyle(Color.mainBlack)
                .frame(width: 52, height: 52)
                .background {
                    Circle()
                        .fill(Color.subWhite)
                        .applyShadow(
                            color: Color.subBlack,
                            alpha: 0.05,
                            x: 0,
                            y: 4,
                            blur: 4
                        )
                }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .opacity(isVisible ? 1 : 0)
    }
}
