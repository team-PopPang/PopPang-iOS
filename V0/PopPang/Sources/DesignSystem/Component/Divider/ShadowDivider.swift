//
//  ShadowDivider.swift
//  PopPang
//
//  Created by 김동현 on 10/12/25.
//

import SwiftUI

struct ShadowDivider: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black.opacity(0.1),
                Color.black.opacity(0.0)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 3)         // 높이는 TabBar shadow와 동일하게
        .blur(radius: 2)          // 퍼짐 효과
        .allowsHitTesting(false)  // 터치 방해 방지
    }
}
