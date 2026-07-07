//
//  SNSButton.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI

// MARK: - 소셜 버튼
struct SNSButton: View {
    let imageName: String
    let buttonTitle: String
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)
                
                Text(buttonTitle)
                    .ppStyleFont(.scdream(.medium, size: 10))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .foregroundStyle(Color.mainGray6)
            .background(Color.mainGray5)
            .cornerRadius(17)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

#Preview {
    @Previewable @State var isFavorite: Bool = false
    VStack {
        SNSButton(imageName: "insta",
                  buttonTitle: "인스타그램") {
        }
    }
    .padding(.horizontal, 20)
}
