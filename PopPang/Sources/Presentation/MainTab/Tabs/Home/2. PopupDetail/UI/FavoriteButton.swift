//
//  FavoriteButton.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI

// MARK: - 찜 버튼
//struct FavoriteButton: View {
//    var isFavorite: Bool
//    var buttonImage: String
//    var buttonImage2: String
//    var textColor: Color = .mainWhite
//    var buttonColor: Color = .mainOrange
//
//    var height: CGFloat = 40
//    var action: () -> Void
//    
//    var body: some View {
//        Button {
//          action()
//        } label: {
//            Image(isFavorite ? buttonImage2 : buttonImage)
//                .renderingMode(.template)
//                .resizable()
//                .aspectRatio(contentMode: .fit)
//                .frame(width: height, height: height)
//                .foregroundStyle(Color.mainOrange)
//        }
//        .buttonStyle(PressableButtonStyle())
//    }
//}


 
// MARK: - 찜 버튼 기존
struct FavoriteButton: View {
    var isFavorite: Bool
    var buttonImage: String  // 스트로크 이미지
    var buttonImage2: String // 색칠된 이미지
    var textColor: Color = .mainWhite
    var buttonColor: Color = .mainOrange

    var height: CGFloat = 40
    var action: () -> Void
    
    var body: some View {
        Button {
          action()
        } label: {
            Image(isFavorite ? buttonImage2 : buttonImage)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .foregroundStyle(isFavorite ? Color.mainOrange : Color.black)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct ImageButton: View {
    var buttonImage: String  // 스트로크 이미지
    var textColor: Color = .mainWhite
    var buttonColor: Color = .mainOrange

    var height: CGFloat = 40
    var action: () -> Void
    
    var body: some View {
        Button {
          action()
        } label: {
            Image( buttonImage)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .foregroundStyle(Color.black)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

