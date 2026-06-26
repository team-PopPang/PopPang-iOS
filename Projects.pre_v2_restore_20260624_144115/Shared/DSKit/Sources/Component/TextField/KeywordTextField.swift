import SwiftUI

public struct KeywordTextField: View {
    var placeholder: String
    @Binding var text: String

    public init(placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        _text = text
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                TextField("", text: $text)
                    .font(.scdream(.medium, size: 12))
                    .frame(height: 48)
                    .keyboardType(.default)
                    .padding(.horizontal, 12)
                    .tint(.mainBlack)
                    .background(Color.subWhite)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color.mainGray7)
                            .padding(.horizontal, 5)
                    }
            }

            if text.isEmpty {
                Text(placeholder)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray2)
                    .opacity(text.isEmpty ? 1 : 0)
                    .padding(.horizontal, 12)
            }
        }
    }
}
