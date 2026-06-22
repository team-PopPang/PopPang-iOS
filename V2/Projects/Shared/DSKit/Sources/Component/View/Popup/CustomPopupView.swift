import SwiftUI

public struct CustomPopupView: View {
    private let title: String
    private let content: String
    private let isCenter: Bool
    private let onDismiss: () -> Void

    public init(
        title: String,
        content: String,
        isCenter: Bool = false,
        onDismiss: @escaping () -> Void
    ) {
        self.title = title
        self.content = content
        self.isCenter = isCenter
        self.onDismiss = onDismiss
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .ppStyleFont(.scdream(.bold, size: 17))
                    .frame(maxWidth: .infinity, alignment: .center)

                Text(content)
                    .ppStyleFont(.scdream(.regular, size: 14))
                    .multilineTextAlignment(isCenter ? .center : .leading)
                    .frame(maxWidth: .infinity, alignment: isCenter ? .center : .leading)
                    .padding(.top, 20)
                    .padding(.horizontal, isCenter ? 30 : 10)

                Button {
                    onDismiss()
                } label: {
                    Text("확인")
                        .ppStyleFont(.scdream(.medium, size: 15))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainBlack)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .contentShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(.top, 20)
            }
            .padding(EdgeInsets(top: 30, leading: 20, bottom: 20, trailing: 20))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mainWhite)
            )
            .padding(.horizontal, 30)
        }
    }
}
