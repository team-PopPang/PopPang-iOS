//
//  AlertButton.swift
//  PopPang
//
//  Created by 김동현 on 9/26/25.
//

import SwiftUI

struct AlertButton: View {
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image("Bell")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
                .padding(10)
        }
    }
}
#Preview {
    AlertButton {
        
    }
}
