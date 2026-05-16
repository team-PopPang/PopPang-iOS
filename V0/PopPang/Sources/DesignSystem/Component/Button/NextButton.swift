//
//  NextButton.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

struct MainOrangeButton: View {
    var buttonTitle: String
    var textColor: Color = .mainWhite
    var buttonColor: Color = .mainOrange
    var isReversed: Bool = false
    var height: CGFloat = 56
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(buttonTitle)
                .font(.scdream(.bold, size: 14))
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isReversed ? buttonColor : textColor)
                .background(isReversed ? .subWhite : buttonColor)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.mainOrange, lineWidth: isReversed ? 1 : 0)
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0) // 눌릴 때 살짝 줄어듦
            .opacity(configuration.isPressed ? 0.85 : 1.0)     // 눌릴 때 살짝 어두워짐
            // animation 대신 즉각 반응 → 더 민감하게
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    MainOrangeButton(buttonTitle: "다음") {
        
    }
    MainOrangeButton(buttonTitle: "다음", isReversed: true) {
        
    }
}
