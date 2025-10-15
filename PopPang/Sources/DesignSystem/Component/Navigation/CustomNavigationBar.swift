//
//  CustomNavigationBar.swift
//  PopPang
//
//  Created by 김동현 on 10/15/25.
//

import SwiftUI

struct CustomNavigationBar<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    var body: some View {
        HStack {
            content
        }
        .padding(.top, 10)
        .padding(.horizontal, .contentPadding)
        .frame(height: 45 + 10) // 필요하면 아래 패딩 추가
    }
}

