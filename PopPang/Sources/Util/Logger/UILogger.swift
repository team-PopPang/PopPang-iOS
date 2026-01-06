//
//  UILogger.swift
//  PopPang
//
//  Created by 김동현 on 1/6/26.
//

import SwiftUI

extension ShapeStyle where Self == Color {
    static var random: Color {
        Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

extension View  {
    /// body 재평가 / 업데이트 시 랜덤 배경 색 적용
    func debugRandomBackground() -> some View {
        let color = Color.random
        return self
            .background(color.opacity(0.25))
            .overlay {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(color, lineWidth: 1)
            }
    }
}
