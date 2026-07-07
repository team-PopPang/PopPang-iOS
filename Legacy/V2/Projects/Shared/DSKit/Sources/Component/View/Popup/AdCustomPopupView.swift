import SwiftUI

public struct AdCustomPopupView: View {
    private let imageURL: String?
    private let title: String?
    private let content: String?
    private let onDismiss: () -> Void
    private let onDontShowToday: () -> Void

    public init(
        imageURL: String?,
        title: String?,
        content: String?,
        onDismiss: @escaping () -> Void,
        onDontShowToday: @escaping () -> Void
    ) {
        self.imageURL = imageURL
        self.title = title
        self.content = content
        self.onDismiss = onDismiss
        self.onDontShowToday = onDontShowToday
    }

    public var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                if let imageURL {
                    Image(imageURL)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .cornerRadius(12, corners: [.topLeft, .topRight])
                }

                VStack(spacing: 0) {
                    if let title {
                        Text(title)
                            .font(.scdream(.bold, size: 17))
                    }

                    if let content {
                        Text(content)
                            .font(.scdream(.regular, size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                    }

                    HStack(spacing: 0) {
                        Button {
                            onDontShowToday()
                        } label: {
                            Text("오늘 하루 보지 않기")
                                .font(.scdream(.bold, size: 14))
                                .foregroundStyle(Color.mainBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                        }

                        Button {
                            onDismiss()
                        } label: {
                            Text("닫기")
                                .font(.scdream(.bold, size: 14))
                                .foregroundStyle(Color.mainOrange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                        }
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mainWhite)
            )
            .padding(.horizontal, 30)
        }
    }
}
