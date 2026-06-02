import SwiftUI

public struct SearchTextField: View {
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
                    .font(.scdream(.medium, size: 11))
                    .frame(height: 45)
                    .keyboardType(.default)
                    .padding(.horizontal, 16)
                    .tint(.mainBlack)
                    .background(Color.mainGray4)
                    .cornerRadius(5)
                    .contentShape(Rectangle())
                    .overlay(
                        HStack {
                            Spacer()
                            DSKitResource.image("Search")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color.mainGray)
                                .frame(width: 17, height: 17)
                                .padding(.trailing, 16)
                                .allowsHitTesting(false)
                        }
                    )
            }

            if text.isEmpty {
                Text(placeholder)
                    .ppStyleFont(.scdream(.regular, size: 11))
                    .foregroundStyle(Color.mainGray)
                    .padding(.horizontal, 15)
                    .opacity(text.isEmpty ? 1 : 0)
            }
        }
    }
}
