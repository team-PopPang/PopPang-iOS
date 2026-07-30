import SwiftUI
import UIKit

public struct FontStyleModifier: ViewModifier {
    let font: UIFont
    let lineHeight: CGFloat
    let letterSpacing: CGFloat

    public func body(content: Content) -> some View {
        let lineSpacing = font.pointSize * (lineHeight - 1)

        return content
            .font(Font(font))
            .padding(.vertical, lineSpacing / 2)
            .lineSpacing(lineSpacing)
            .tracking(font.pointSize * letterSpacing)
    }
}

public struct StyleModifier: ViewModifier {
    let font: UIFont
    let lineHeight: CGFloat
    let letterSpacing: CGFloat

    public func body(content: Content) -> some View {
        let lineSpacing = font.pointSize * (lineHeight - 1)

        return content
            .padding(.vertical, lineSpacing / 2)
            .lineSpacing(lineSpacing)
            .tracking(font.pointSize * letterSpacing)
    }
}

public struct PointFontStyleModifier: ViewModifier {
    let font: UIFont
    let lineHeightPt: CGFloat
    let letterSpacingPt: CGFloat

    public func body(content: Content) -> some View {
        // SwiftUI adds lineSpacing on top of the font's natural line height.
        let lineSpacing = max(0, lineHeightPt - font.lineHeight)

        return content
            .font(Font(font))
            .padding(.vertical, lineSpacing / 2)
            .lineSpacing(lineSpacing)
            .tracking(letterSpacingPt)
    }
}

public extension View {
    func ppStyleFont(
        _ font: UIFont,
        lineHeight: CGFloat = 1.4,
        letterSpacing: CGFloat = 0.02
    ) -> some View {
        modifier(
            FontStyleModifier(
                font: font,
                lineHeight: lineHeight,
                letterSpacing: letterSpacing
            )
        )
    }

    func ppStyle(
        _ font: UIFont,
        lineHeight: CGFloat,
        letterSpacing: CGFloat = 0.0
    ) -> some View {
        modifier(
            StyleModifier(
                font: font,
                lineHeight: lineHeight,
                letterSpacing: letterSpacing
            )
        )
    }

    func ppStyleFontFixedSpacing(
        _ font: UIFont,
        lineHeight: CGFloat = 1.4,
        letterSpacingPt: CGFloat = 0
    ) -> some View {
        let lineSpacing = font.pointSize * (lineHeight - 1)
        return self
            .font(Font(font))
            .padding(.vertical, lineSpacing / 2)
            .lineSpacing(lineSpacing)
            .tracking(letterSpacingPt)
    }

    func ppStyleFont(
        _ font: UIFont,
        lineHeightPt: CGFloat,
        letterSpacingPt: CGFloat = 0
    ) -> some View {
        modifier(
            PointFontStyleModifier(
                font: font,
                lineHeightPt: lineHeightPt,
                letterSpacingPt: letterSpacingPt
            )
        )
    }
}
