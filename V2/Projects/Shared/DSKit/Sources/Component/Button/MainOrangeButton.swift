import SwiftUI

public struct MainOrangeButton: View {
    var buttonTitle: String
    var textColor: Color
    var buttonColor: Color
    var isReversed: Bool
    var height: CGFloat
    var action: () -> Void

    public init(
        buttonTitle: String,
        textColor: Color = .mainWhite,
        buttonColor: Color = .mainOrange,
        isReversed: Bool = false,
        height: CGFloat = 56,
        action: @escaping () -> Void
    ) {
        self.buttonTitle = buttonTitle
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
                .font(.scdream(.bold, size: 14))
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
