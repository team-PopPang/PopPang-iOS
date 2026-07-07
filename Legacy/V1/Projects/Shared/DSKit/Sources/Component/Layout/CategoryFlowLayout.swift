import SwiftUI

public struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    public init(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
                .font(.scdream(.medium, size: 12))
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            isSelected ? Color.mainOrange : .clear,
                            lineWidth: 1.5
                        )
                        .background {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(isSelected ? Color.categoryOrange : Color.mainGray4)
                        }
                }
                .foregroundStyle(isSelected ? Color.mainOrange : Color.mainGray2)
        }
    }
}

public struct FlowLayout<Data: RandomAccessCollection, Content: View, ID: Hashable>: View {
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let content: (Data.Element) -> Content

    public init(
        _ data: Data,
        id: KeyPath<Data.Element, ID>,
        @ViewBuilder content: @escaping (Data.Element) -> Content
    ) {
        self.data = data
        self.id = id
        self.content = content
    }

    public var body: some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                ForEach(data, id: id) { item in
                    content(item)
                        .padding([.horizontal, .vertical], 4)
                        .alignmentGuide(.leading) { dimension in
                            if abs(width - dimension.width) > geometry.size.width {
                                width = 0
                                height -= dimension.height
                            }

                            let result = width
                            if item[keyPath: id] == data.last?[keyPath: id] {
                                width = 0
                            } else {
                                width -= dimension.width
                            }
                            return result
                        }
                        .alignmentGuide(.top) { _ in
                            let result = height
                            if item[keyPath: id] == data.last?[keyPath: id] {
                                height = 0
                            }
                            return result
                        }
                }
            }
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)
    }
}
