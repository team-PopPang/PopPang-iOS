import Kingfisher
import SwiftUI

public struct GridView: View {
    private let imageURLs: [String]
    private let spacing: CGFloat
    private let itemHeight: CGFloat
    private let horizontalPadding: CGFloat

    private var columns: [GridItem] {
        [
            GridItem(.flexible(), spacing: spacing),
            GridItem(.flexible())
        ]
    }

    public init(
        imageURLs: [String],
        spacing: CGFloat = 15,
        itemHeight: CGFloat = 217,
        horizontalPadding: CGFloat = 20
    ) {
        self.imageURLs = imageURLs
        self.spacing = spacing
        self.itemHeight = itemHeight
        self.horizontalPadding = horizontalPadding
    }

    public var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .center, spacing: 20) {
                ForEach(imageURLs, id: \.self) { url in
                    KFImage(URL(string: url))
                        .placeholder {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: itemHeight)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: itemHeight)
                        .frame(maxWidth: .infinity)
                        .clipped()
                }
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
}
