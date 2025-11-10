//
//  AlertButton.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct IconButton: View {
    var image: String = "Bell"
    var systemImage: Bool = false
    var imageSize: CGFloat = 20
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if systemImage {
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageSize, height: imageSize)
                    .padding(10) // 파란 영역 크기 = 터치 영역
                    // .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6)) // 터치 영역 제한
            } else {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageSize, height: imageSize)
                    .padding(10) // 파란 영역 크기 = 터치 영역
                    // .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6)) // 터치 영역 제한
            }
            
                
        }
        .buttonStyle(PressableButtonStyle())
    }
}
#Preview {
    IconButton {
        
    }
}
