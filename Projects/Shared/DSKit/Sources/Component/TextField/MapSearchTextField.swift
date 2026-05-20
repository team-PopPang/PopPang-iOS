import SwiftUI

public struct MapSearchTextField: View {
    var placeholder: String
    var background: Color
    @Binding var text: String
    @FocusState private var isFocused: Bool
    var onTap: (() -> Void)?

    public init(
        placeholder: String,
        background: Color = .subWhite,
        text: Binding<String>,
        onTap: (() -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.background = background
        _text = text
        self.onTap = onTap
    }

    public var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                TextField("", text: $text)
                    .font(.scdream(.medium, size: 12))
                    .frame(height: 45)
                    .keyboardType(.default)
                    .padding(.horizontal, 10)
                    .tint(.mainBlack)
                    .background(background)
                    .cornerRadius(3)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isFocused = true
                        onTap?()
                    }
                    .overlay {
                        HStack {
                            Spacer()
                            Image("Search")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color.mainGray2)
                                .frame(width: 17, height: 17)
                                .padding(.trailing, 24)
                        }
                    }
            }

            if text.isEmpty {
                Text(placeholder)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray2)
                    .opacity(text.isEmpty ? 1 : 0)
                    .padding(.horizontal, 10)
            }
        }
    }
}
