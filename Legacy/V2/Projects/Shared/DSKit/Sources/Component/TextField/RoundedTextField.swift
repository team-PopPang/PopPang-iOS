import SwiftUI

public struct RoundedTextField: View {
    var placeholder: String
    @Binding var text: String
    var validationState: NicknameValidationState

    private var borderColor: Color {
        switch validationState {
        case .none, .checking:
            return .mainGray3
        case .success:
            return .mainGreen
        case .duplicate, .invalidSpace, .tooShort:
            return .mainRed
        }
    }

    private var statusIcon: String? {
        switch validationState {
        case .success:
            return "Success"
        case .duplicate, .invalidSpace, .tooShort:
            return "Fail"
        default:
            return nil
        }
    }

    public init(
        placeholder: String,
        text: Binding<String>,
        validationState: NicknameValidationState = .none
    ) {
        self.placeholder = placeholder
        _text = text
        self.validationState = validationState
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray2)
                    .padding(.horizontal, 16)
                    .opacity(text.isEmpty ? 1 : 0)
            }

            HStack {
                TextField("", text: $text)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainBlack)
                    .keyboardType(.default)
                    .padding(.horizontal, 16)
                    .tint(.mainBlack)

                if let icon = statusIcon {
                    Image(icon)
                        .resizable()
                        .frame(width: 15, height: 15)
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(height: 48)
        .cornerRadius(5)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 0.8)
        }
        .animation(.easeInOut(duration: 0.15), value: borderColor)
    }
}
