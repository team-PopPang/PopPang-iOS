//
//  HomeBestHeader.swift
//  HomeFeature
//
//  Created by 김동현 on 6/15/26.
//

import SwiftUI

struct HomeBestHeader: View {
    let nickname: String

    var body: some View {
        HStack(spacing: 0) {
            Text(nickname)
                .foregroundStyle(Color.mainOrange)
                .font(.scdream(.bold, size: 15))

            Text("님을 위한 팝업")
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)

            Spacer()
        }
    }
}
