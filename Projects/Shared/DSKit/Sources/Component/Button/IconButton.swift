import SwiftUI

public struct IconButton: View {
    var image: String
    var systemImage: Bool
    var imageSize: CGFloat
    var action: () -> Void

    public init(
        image: String = "Bell",
        systemImage: Bool = false,
        imageSize: CGFloat = 20,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.systemImage = systemImage
        self.imageSize = imageSize
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            if systemImage {
                Image(systemName: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageSize, height: imageSize)
                    .padding(10)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            } else {
                DSKitResource.image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageSize, height: imageSize)
                    .padding(10)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
            }
        }
        .buttonStyle(PressableButtonStyle())
    }
}
