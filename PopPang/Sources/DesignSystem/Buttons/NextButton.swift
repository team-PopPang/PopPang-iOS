//
//  NextButton.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

struct NextButton: View {
    var buttonTitle: String
    var textColor: Color = .mainWhite
    var buttonColor: Color = .mainOrange
    var action: () -> Void
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(buttonTitle)
                .font(.scdream(.bold, size: 16))
                .frame(height: 56)
                .frame(maxWidth: .infinity)
                .foregroundStyle(textColor)
                .background(buttonColor)
                .clipShape(RoundedRectangle(cornerRadius: 5))
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
    NextButton(buttonTitle: "다음") {
        
    }
}
