import SwiftUI

public struct DropDownView: View {
    var options: [String]
    var anchor: Anchor
    var maxWidth: CGFloat
    var cornerRadius: CGFloat
    var stroke: Color
    var imgSize: CGFloat
    var imgColor: Color
    @Binding var selection: String?
    var overlay: Bool
    var pickedFont: Font
    var pickedColor: Color
    var detailFont: Font
    var detailClicked: Color
    var detailNotClicked: Color

    @State private var showOptions = false
    @Environment(\.colorScheme) private var scheme
    @SceneStorage("drop_down_zindex") private var index = 1000.0
    @State private var zIndex = 1000.0

    public init(
        options: [String],
        anchor: Anchor = .bottom,
        maxWidth: CGFloat = 180,
        cornerRadius: CGFloat = 15,
        stroke: Color = .mainBlack,
        imgSize: CGFloat = 16,
        imgColor: Color = .mainBlack,
        selection: Binding<String?>,
        overlay: Bool = false,
        pickedFont: Font = .scdream(.medium, size: 15),
        pickedColor: Color = .mainBlack,
        detailFont: Font = .scdream(.medium, size: 15),
        detailClicked: Color = .mainBlack,
        detailNotClicked: Color = .mainGray
    ) {
        self.options = options
        self.anchor = anchor
        self.maxWidth = maxWidth
        self.cornerRadius = cornerRadius
        self.stroke = stroke
        self.imgSize = imgSize
        self.imgColor = imgColor
        self._selection = selection
        self.overlay = overlay
        self.pickedFont = pickedFont
        self.pickedColor = pickedColor
        self.detailFont = detailFont
        self.detailClicked = detailClicked
        self.detailNotClicked = detailNotClicked
    }

    public var body: some View {
        GeometryReader { geo in
            let size = geo.size

            VStack(spacing: 0) {
                if showOptions && anchor == .top {
                    optionsView()
                }

                HStack(spacing: 0) {
                    Text(selection ?? "")
                        .font(pickedFont)
                        .foregroundStyle(pickedColor)
                        .lineLimit(1)
                        .animation(.none, value: selection)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: imgSize, height: imgSize)
                        .foregroundStyle(imgColor)
                        .rotationEffect(.degrees(showOptions ? -180 : 0))
                }
                .padding(.horizontal, 15)
                .frame(width: size.width, height: size.height)
                .background(scheme == .dark ? .black : .white)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        index += 1
                        zIndex = index
                        showOptions.toggle()
                    }
                }
                .zIndex(10)

                if showOptions && anchor == .bottom {
                    optionsView()
                }
            }
            .clipped()
            .background(.white)
            .cornerRadius(cornerRadius)
            .overlay {
                if overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(stroke)
                }
            }
            .frame(height: size.height, alignment: anchor == .top ? .bottom : .top)
            .onAppear {
                if selection == nil {
                    selection = options.first
                }
            }
        }
        .frame(maxWidth: maxWidth)
        .frame(height: 40)
        .zIndex(zIndex)
    }

    @ViewBuilder
    func optionsView() -> some View {
        VStack(spacing: 10) {
            ForEach(options, id: \.self) { option in
                HStack(spacing: 0) {
                    Text(option)
                        .font(detailFont)
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.mainBlack)
                        .opacity(selection == option ? 1 : 0)
                }
                .foregroundStyle(selection == option ? detailClicked : detailNotClicked)
                .animation(.none, value: selection)
                .frame(height: 40)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = option
                        showOptions = false
                    }
                }
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 5)
        .transition(.move(edge: anchor == .top ? .bottom : .top))
    }

    public enum Anchor {
        case top
        case bottom
    }
}
