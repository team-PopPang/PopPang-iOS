import SwiftUI
import UIKit

public struct MainOrangeButton: View {
    var buttonTitle: String
    var textFont: UIFont
    var textLineHeightPt: CGFloat
    var textLetterSpacingPt: CGFloat
    var textColor: Color
    var buttonColor: Color
    var isReversed: Bool
    var height: CGFloat
    var action: () -> Void

    public init(
        buttonTitle: String,
        textFont: UIFont = .scdream(.bold, size: 14),
        textLineHeightPt: CGFloat? = nil,
        textLetterSpacingPt: CGFloat = 0,
        textColor: Color = .mainWhite,
        buttonColor: Color = .mainOrange,
        isReversed: Bool = false,
        height: CGFloat = 56,
        action: @escaping () -> Void
    ) {
        self.buttonTitle = buttonTitle
        self.textFont = textFont
        self.textLineHeightPt = textLineHeightPt ?? textFont.lineHeight
        self.textLetterSpacingPt = textLetterSpacingPt
        self.textColor = textColor
        self.buttonColor = buttonColor
        self.isReversed = isReversed
        self.height = height
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            Text(buttonTitle)
                .ppStyleFont(
                    textFont,
                    lineHeightPt: textLineHeightPt,
                    letterSpacingPt: textLetterSpacingPt
                )
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .foregroundStyle(isReversed ? buttonColor : textColor)
                .background(isReversed ? .subWhite : buttonColor)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.mainOrange, lineWidth: isReversed ? 1 : 0)
                }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
