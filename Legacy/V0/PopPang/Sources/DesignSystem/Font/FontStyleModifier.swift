//
//  FontStyleModifier.swift
//  PopPang
//
//  Created by 김동현 on 9/30/25.
//

import SwiftUI

// MARK: - 폰트, 줄간격(lineHeight), 자간(lineSpacing) 동시에 적용하는 modifier
struct FontStyleModifier: ViewModifier {
    
    let font: UIFont
    let lineHeight: CGFloat    // 줄간격 배수(ex: 1.4 -> 140%)
    let letterSpacing: CGFloat // 자간 배수(ex: 0.02 -> 2%)
    
    func body(content: Content) -> some View {
        // 줄간격 계산 -> 폰트 크기 * (배수-1)
        // ex) 14pt 글자, lineHeight = 1.4
        // -> 14 * 0.4 = 5.6
        let lineSpacing = font.pointSize * (lineHeight - 1)
        
        return content
            .font(Font(font)) // UIFont -> Font
            .padding(.vertical, lineSpacing / 2)      // 위 아래 균등 패딩을 주어 줄간격 맞추기
            .lineSpacing(lineSpacing)                 // 줄과 줄 사이 간격 설정
            .tracking(font.pointSize * letterSpacing) // 자간 설정(폰트 크기 기반)
    }
}

// MARK: - 폰트 적용 없이 줄간격(lineHeight), 자간(lineSpacing) 동시에 적용하는 modifier
// 폰트는 별도 지정시 사용
struct StyleModifier: ViewModifier {
    
    let font: UIFont
    let lineHeight: CGFloat    // 줄간격 배수(ex: 1.4 -> 140%)
    let letterSpacing: CGFloat // 자간 배수(ex: 0.02 -> 2%)
    
    func body(content: Content) -> some View {
        // 줄간격 계산 -> 폰트 크기 * (배수-1)
        // ex) 14pt 글자, lineHeight = 1.4
        // -> 14 * 0.4 = 5.6
        let lineSpacing = font.pointSize * (lineHeight - 1)
        
        return content
            .padding(.vertical, lineSpacing / 2)      // 위 아래 균등 패딩을 주어 줄간격 맞추기
            .lineSpacing(lineSpacing)                 // 줄과 줄 사이 간격 설정
            .tracking(font.pointSize * letterSpacing) // 자간 설정(폰트 크기 기반)
    }
}

extension View {
    
    
    /// 팝팡 스타일 폰트(폰트 + 줄간격 + 자간)
    /// - Parameters:
    ///   - font: 적용할 UIFont
    ///   - lineHeight: 줄간격 배수 (ex: 1.4 -> 140%)
    ///   - letterSpacing: 자간 배수 (ex: 0.02 -> 2%)
    /// - Returns: View
    func ppStyleFont(_ font: UIFont,
                     lineHeight: CGFloat = 1.4,
                     letterSpacing: CGFloat = 0.02) -> some View {
        self.modifier(FontStyleModifier(font: font,
                                        lineHeight: lineHeight,
                                        letterSpacing: letterSpacing))
    }
    
    
    /// 팝팡 스타일 폰트 (줄간격 + 자간, 폰트는 외부에서)
    /// - Parameters:
    ///   - font: 기준이 될 UIFint(줄간격과 자간 계산용)
    ///   - lineHeight: 줄간격 배수 (ex: 1.4 -> 140%)
    ///   - letterSpacing: 자간 배수 (ex: 0.02 -> 2%)
    /// - Returns: 폰트는 따로 .font()지정시 사용
    func ppStyle(_ font: UIFont,
                 lineHeight: CGFloat,
                 letterSpacing: CGFloat = 0.0) -> some View {
        self.modifier(StyleModifier(font: font,
                                    lineHeight: lineHeight,
                                    letterSpacing: letterSpacing))
    }
    
    
    /// 팝팡 스타일 폰트 (자간: pt 단위)
    /// - Parameters:
    ///   - font: 적용할 UIFont
    ///   - lineHeight: 줄간격 배수 (ex: 1.4 -> 140%)
    ///   - letterSpacingPt: 자간 pt 단위 (ex: -1 -> -1pt)
    func ppStyleFontFixedSpacing(_ font: UIFont,
                                 lineHeight: CGFloat = 1.4,
                                 letterSpacingPt: CGFloat = 0) -> some View {
        let lineSpacing = font.pointSize * (lineHeight - 1)
        return self
            .font(Font(font))
            .padding(.vertical, lineSpacing / 2)
            .lineSpacing(lineSpacing)
            .tracking(letterSpacingPt)
    }
}


#Preview {
    Text("제목 텍스트")
        .ppStyleFont(.scdream(.bold, size: 18),
                   lineHeight: 1.4,
                   letterSpacing: 0.02)
    
    Text("제목 텍스트")
        .ppStyleFont(.scdream(.bold, size: 18))

    Text("본문 텍스트")
      .font(.headline) // SwiftUI 폰트 직접 지정
      .ppStyle(UIFont.systemFont(ofSize: 16),
               lineHeight: 1.5,
               letterSpacing: 0.02)
}
