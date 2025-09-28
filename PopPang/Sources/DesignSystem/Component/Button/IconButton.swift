//
//  AlertButton.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct IconButton: View {
    var image: String = "Bell"
    var imageSize: CGFloat = 20
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: imageSize, height: imageSize)
                .padding(10)
        }
        .buttonStyle(PressableButtonStyle())
    }
}
#Preview {
    IconButton {
        
    }
}
