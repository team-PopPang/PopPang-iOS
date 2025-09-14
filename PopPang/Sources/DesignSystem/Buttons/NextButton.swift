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
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    NextButton(buttonTitle: "다음") {
        
    }
}
