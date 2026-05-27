import Compound
import Kingfisher
import Core
import Domain
import DSKit
import SwiftUI

public struct SearchFeatureView: View {
    @State private var compound: SearchFeatureCompound
    @FocusState private var isFocused: Bool

    private let nickname: String
    private let onDismiss: () -> Void
    private let onSelectPopup: (Popup) -> Void

    public init(
        userUuid: String = "demo-user",
        nickname: String = "홍길동",
        recentSearchStorage: RecentSearchStorage = RecentSearchStorage(store: UserDefaultsStore()),
        onDismiss: @escaping () -> Void = {},
        onSelectPopup: @escaping (Popup) -> Void = { _ in }
    ) {
        _compound = State(
            wrappedValue: SearchFeatureCompound(
                userUuid: userUuid,
                recentSearchStorage: recentSearchStorage
            )
        )
        self.nickname = nickname
        self.onDismiss = onDismiss
        self.onSelectPopup = onSelectPopup
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        onDismiss()
                    } label: {
                        DSKitResource.image("backButton")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 14, height: 14)
                            .foregroundStyle(Color.subBlack)
                    }
                    .padding(.trailing, 10)
                    .accessibilityIdentifier("home_search_backbutton")

                    SearchTextField(
                        placeholder: "궁금한 장소를 검색해보세요",
                        text: Binding(
                            get: { compound.state.searchText },
                            set: { searchText in
                                compound.cancelAllActions()
                                compound.send(.searchTextChanged(searchText))
                            }
                        )
                    )
                    .focused($isFocused)
                    .accessibilityIdentifier("home_search_textfield")
                }
                .padding(.top, 10)
                .padding(.leading, .contentPadding)
                .padding(.trailing, 15)
                .padding(.bottom, 10)

                VStack(spacing: 0) {
                    if compound.state.searchPopupList.isEmpty {
                        HStack(spacing: 0) {
                            Text(nickname)
                                .foregroundStyle(Color.mainOrange)
                                .font(.scdream(.bold, size: 12))

                            Text(recentKeywordTitleSuffix)
                                .font(.scdream(.regular, size: 12))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        SearchFlowLayout {
                            ForEach(compound.state.recentKeywords, id: \.self) { keyword in
                                SearchFlowButton(title: keyword) {
                                    compound.cancelAllActions()
                                    compound.send(.recentKeywordTapped(keyword))
                                } onRemove: {
                                    compound.send(.recentKeywordRemoved(keyword))
                                }
                            }
                            .padding(4)
                        }
                        .padding(.top, 15)

                        if compound.state.searchText.isEmpty == false && compound.state.isLoading == false {
                            VStack(spacing: 0) {
                                DSKitResource.image("noResult")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 50, height: 50)

                                Text("검색결과가 없습니다.")
                                    .ppStyleFont(.scdream(.medium, size: 14))
                                    .foregroundStyle(Color.mainBlack)
                                    .padding(.top, 10)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }

                    if compound.state.isLoading {
                        ProgressView()
                            .padding(.top, 24)
                    }

                    if let errorMessage = compound.state.errorMessage {
                        Text(errorMessage)
                            .ppStyleFont(.scdream(.regular, size: 12))
                            .foregroundStyle(Color.mainRed)
                            .padding(.top, 12)
                    }

                    SearchGridPopupScrollView(
                        popups: compound.state.searchPopupList,
                        onSelect: onSelectPopup
                    )
                }
                .padding(.top, 20)
                .padding(.horizontal, .contentPadding)

                Spacer()
            }
        }
        .task {
            isFocused = true
            compound.send(.onAppear)
        }
    }

    private var recentKeywordTitleSuffix: String {
        compound.state.recentKeywords.isEmpty
            ? "님의 최근 본 검색어가 없습니다"
            : "님의 최근 본 검색어예요"
    }
}

private struct SearchGridPopupScrollView: View {
    let popups: [Popup]
    let onSelect: (Popup) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(popups) { popup in
                    VStack(alignment: .leading) {
                        SearchGridPopupCell(popup: popup)
                            .onTapGesture {
                                onSelect(popup)
                            }
                            .accessibilityElement(children: .ignore)
                            .accessibilityIdentifier("home_search_cell")
                    }
                }
            }
        }
    }
}

private struct SearchGridPopupCell: View {
    let popup: Popup

    private let cellWidth: CGFloat = (UIScreen.main.bounds.width - 15 * 3) / 2

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .placeholder {
                        Rectangle()
                            .fill(Color.subWhite)
                            .frame(width: cellWidth, height: 217)
                    }
                    .downSampled(.searchGridPopupCell)
                    .scaledToFill()
                    .frame(width: cellWidth, height: 217)
                    .clipped()
            }
            .frame(height: 217)

            Text(popup.roadAddress.shortAddress)
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainBlack)
                .padding(.top, 10)

            Text(popup.name)
                .font(.scdream(.medium, size: 14))
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 5)

            Text("\(popup.startDate, formatter: DateFormatter.popupDateFormat) - \(popup.endDate, formatter: DateFormatter.popupDateFormat)")
                .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
                .foregroundStyle(Color.mainGray)
                .padding(.top, 5)
        }
    }
}

private extension KFImage {
    enum DownSamplePreset {
        case searchGridPopupCell

        var size: CGSize {
            switch self {
            case .searchGridPopupCell:
                CGSize(width: (UIScreen.main.bounds.width - 15 * 3) / 2, height: 217)
            }
        }
    }

    func downSampled(_ preset: DownSamplePreset) -> KFImage {
        let scale = UIScreen.main.scale
        return setProcessor(
            DownsamplingImageProcessor(
                size: CGSize(
                    width: preset.size.width * scale,
                    height: preset.size.height * scale
                )
            )
        )
        .cacheOriginalImage()
    }
}
