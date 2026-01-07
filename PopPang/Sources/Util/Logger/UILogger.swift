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


// ======================================
// MARK: - Diff-based Debug (핵심)
// ======================================
private struct _DebugDiffKey: Equatable {
    let values: [AnyHashable]
}

private struct DebugDiffRandomBackgroundModifier<Key: Equatable>: ViewModifier {
    let diffKey: Key
    @State private var color: Color = .random
    
    init(diffKey: Key) {
        self.diffKey = diffKey
        print("🧨 Modifier INIT")
    }

    func body(content: Content) -> some View {
        content
            .background(color.opacity(0.25))
            .overlay {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(color, lineWidth: 1)
            }
            .onChange(of: diffKey) { _, _ in
                print("🔥 diffKey changed")
                color = .random
            }
    }
}

// MARK: - body가 다시 계산되었는지를 보여주고,
extension View  {
    /// body가 재평가될 때마다 색이 바뀌는 디버그용 배경
    /// - 목적: "body가 다시 계산됐는지" 확인
    func debugBodyRandomBackground() -> some View {
        let color = Color.random
        return self
            .background(color.opacity(0.25))
            .overlay {
                RoundedRectangle(cornerRadius: 0)
                    .stroke(color, lineWidth: 1)
            }
    }
}


// MARK: - diff 기준이 실제로 달라졌는지를 보여준다.(diff는 항상 실행된다, diff 결과가 달라짐을 인식하기 위한 코드다)
extension View {
    /// SwiftUI diff 기준 값이 변경될 때만 색이 바뀌는 디버그용 배경
    /// - 자식 View body 재실행 ❌
    /// - 스크롤 / 셀 재사용 ❌
    /// - diff 기준 값 변경 ⭕️
    ///
    /// 사용 예:
    /// .debugDiffRandomBackground(id, isLiked, count)
    func debugDiffRandomBackground(
        _ values: AnyHashable...
    ) -> some View {
        modifier(
            DebugDiffRandomBackgroundModifier(
                diffKey: _DebugDiffKey(values: values)
            )
        )
    }
}
