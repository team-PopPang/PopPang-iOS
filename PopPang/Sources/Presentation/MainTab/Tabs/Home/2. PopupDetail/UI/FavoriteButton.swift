//
//  FavoriteButton.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI

// MARK: - 찜 버튼
struct FavoriteButton: View {
    var isFavorite: Bool
    var buttonTitle: String
    var buttonTitle2: String
    var textColor: Color = .mainWhite
    var buttonColor: Color = .mainOrange

    var height: CGFloat = 40
    var action: () -> Void
    
    var body: some View {
        Button {
          action()
        } label: {
            Text(isFavorite ? buttonTitle2 : buttonTitle)
                .font(.scdream(.medium, size: 12))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .foregroundStyle(Color.mainWhite)
                .background(isFavorite ?
                            Color.mainGray6 : Color.mainOrange)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(PressableButtonStyle())
    }
}
