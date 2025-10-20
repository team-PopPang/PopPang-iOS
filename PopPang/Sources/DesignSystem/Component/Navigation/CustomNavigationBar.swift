//
//  CustomNavigationBar.swift
//  PopPang
//
//  Created by 김동현 on 10/15/25.
//

import SwiftUI

struct CustomNavigationBar<Content: View>: View {
    let content: Content
    let hPadding: CGFloat
    init(hPadding: CGFloat = .contentPadding,
         @ViewBuilder content: () -> Content
    ) {
        self.hPadding = hPadding
        self.content = content()
    }
    var body: some View {
        HStack(spacing: 0) {
            content
        }
        .padding(.top, 10)
        .padding(.horizontal, hPadding)
        .frame(height: 45 + 10) // 필요하면 아래 패딩 추가
    }
}

