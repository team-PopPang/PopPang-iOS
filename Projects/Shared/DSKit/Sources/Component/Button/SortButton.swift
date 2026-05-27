import SwiftUI

public struct SortButton: View {
    @Binding var selectedOption: SortOption
    let fgColor: Color = .mainGray5
    let bgColor: Color = .subWhite
    var action: () -> Void

    public init(
        selectedOption: Binding<SortOption>,
        action: @escaping () -> Void
    ) {
        self._selectedOption = selectedOption
        self.action = action
    }

    public var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Text(selectedOption.title)
                    .ppStyleFont(.scdream(.light, size: 10))
                    .foregroundStyle(Color.mainGray)

                Image(systemName: "chevron.down")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 10, height: 10)
                    .foregroundStyle(Color.mainGray)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .frame(width: 80)
            .background(bgColor)
            .cornerRadius(17)
            .overlay {
                RoundedRectangle(cornerRadius: 17)
                    .stroke(lineWidth: 1)
                    .foregroundColor(fgColor)
            }
        }
    }

    public enum SortOption: String, CaseIterable, Sendable {
        case newest = "NEWEST"
        case closingSoon = "CLOSING_SOON"
        case mostFavorited = "MOST_FAVORITED"
        case mostViewed = "MOST_VIEWED"

        public var title: String {
            switch self {
            case .newest:
                return "최신순"
            case .closingSoon:
                return "마감순"
            case .mostFavorited:
                return "찜순"
            case .mostViewed:
                return "조회순"
            }
        }
    }
}

public struct SortButtonSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedOption: SortButton.SortOption

    let backFont: Font = .system(size: 17, weight: .bold)

    public init(selectedOption: Binding<SortButton.SortOption>) {
        self._selectedOption = selectedOption
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("정렬")
                    .foregroundStyle(Color.mainBlack)
                    .ppStyleFont(.scdream(.bold, size: 17))
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.black)
                        .font(backFont)
                }
                .accessibilityIdentifier("home_sheet_close_button")
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(SortButton.SortOption.allCases, id: \.self) { option in
                    Button {
                        selectedOption = option
                        dismiss()
                    } label: {
                        HStack(spacing: 15) {
                            DSKitResource.image(selectedOption == option ? "circle_filled" : "circle")
                                .resizable()
                                .frame(width: 15, height: 15)
                                .foregroundColor(selectedOption == option ? .orange : .gray)
                            Text(option.title)
                                .foregroundStyle(Color.mainBlack)
                                .ppStyleFont(.scdream(.regular, size: 15))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .frame(height: 40)
                    }
                    .accessibilityIdentifier("home_sort_option_\(option.rawValue)")
                }
            }
            .padding(.top, 28)

            Spacer()
        }
        .padding(.top, 28)
        .padding(.horizontal, 28)
        .presentationDragIndicator(.visible)
    }
}
