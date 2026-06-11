import SwiftUI

public struct PopupCategoryTag: View {
    let text: String

    public init(text: String) {
        self.text = text
    }

    public var body: some View {
        Text(text)
            .ppStyleFont(.scdream(.regular, size: 11))
            .foregroundStyle(Color.subOrange)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(Color.subOrange2)
            .cornerRadius(10)
    }
}
