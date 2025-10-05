//
//  View+.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import SwiftUI

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    init(radius: CGFloat, corners: UIRectCorner) {
        self.radius = radius
        self.corners = corners
    }
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(
            RoundedCorner(radius: radius, corners: corners)
        )
    }
}

// MARK: - 애니메이션 제거
extension View {
    func withoutAnimation() -> some View {
        self.transaction { transaction in
            transaction.disablesAnimations = true
        }
    }
}

// MARK: - 디자인
extension View {
    func applyShadow(
        color: Color = .black,    // 그림자 색상 (기본 검은색)
        alpha: Double = 0.5,      // 투명도
        x: CGFloat = 0,           // X축 방향 offset
        y: CGFloat = 20,          // Y축 방향 offset
        blur: CGFloat = 35        // 블러 정도
    ) -> some View {
        self.shadow(
            color: color.opacity(alpha), // 투명도 반영된 색상
            radius: blur / 2,            // blur를 반으로 줄여 자연스러운 그림자
            x: x,
            y: y
        )
    }
}


