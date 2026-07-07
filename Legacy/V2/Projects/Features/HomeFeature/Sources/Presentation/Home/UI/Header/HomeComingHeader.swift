//
//  HomeComingHeader.swift
//  HomeFeature
//
//  Created by 김동현 on 6/15/26.
//

import SwiftUI
import Domain
import DSKit

struct HomeComingHeader: View {
    let userUuid: String
    let popups: [Popup]
    let onTap: (String, [Popup]) -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("COMING SOON")
                    .font(.scdream(.medium, size: 11))
                    .foregroundStyle(Color.mainOrange)

                Text("오픈 예정 팝업")
                    .font(.scdream(.bold, size: 15))
                    .foregroundStyle(Color.mainBlack)
            }

            Spacer()

            Button {
                onTap(userUuid, popups)
            } label: {
                DSKitResource.image("navigationButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
            .accessibilityIdentifier("home_comming_button")
        }
    }
}
