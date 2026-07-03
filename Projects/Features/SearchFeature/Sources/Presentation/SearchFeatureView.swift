import ComposableArchitecture
import Core
import Domain
import DSKit
import Kingfisher
import PopupDetailFeature
import ReviewFeature
import SwiftUI

public struct SearchFeatureView: View {
    @Bindable var store: StoreOf<SearchFeature>
    @FocusState private var isFocused: Bool

    public init(store: StoreOf<SearchFeature>) {
        self.store = store
    }

    public var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Button {
                        store.send(.dismissTapped)
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
                            get: { store.searchText },
                            set: { store.send(.searchTextChanged($0)) }
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
                    if store.searchPopupList.isEmpty {
                        HStack(spacing: 0) {
                            Text(store.nickname)
                                .foregroundStyle(Color.mainOrange)
                                .font(.scdream(.bold, size: 12))

                            Text(recentKeywordTitleSuffix)
                                .font(.scdream(.regular, size: 12))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        SearchFlowLayout {
                            ForEach(store.recentKeywords, id: \.self) { keyword in
                                SearchFlowButton(title: keyword) {
                                    store.send(.recentKeywordTapped(keyword))
                                } onRemove: {
                                    store.send(.recentKeywordRemoved(keyword))
                                }
                            }
                            .padding(4)
                        }
                        .padding(.top, 15)

                        if store.searchText.isEmpty == false && store.isLoading == false {
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

                    if store.isLoading {
                        ProgressView()
                            .padding(.top, 24)
                    }

                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .ppStyleFont(.scdream(.regular, size: 12))
                            .foregroundStyle(Color.mainRed)
                            .padding(.top, 12)
                    }

                    SearchGridPopupScrollView(
                        popups: store.searchPopupList,
                        onSelect: { popup in
                            store.send(.popupSelected(popup))
                        }
                    )
                }
                .padding(.top, 20)
                .padding(.horizontal, .contentPadding)

                Spacer()
            }
        } destination: { store in
            switch store.state {
            case .popupDetail:
                if let store = store.scope(state: \.popupDetail, action: \.popupDetail) {
                    SearchPopupDetailDestinationView(store: store)
                }
            case .reviewDetail:
                if let store = store.scope(state: \.reviewDetail, action: \.reviewDetail) {
                    SearchReviewDetailDestinationView(store: store)
                }
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .task {
            isFocused = true
        }
    }

    private var recentKeywordTitleSuffix: String {
        store.recentKeywords.isEmpty
            ? "님의 최근 본 검색어가 없습니다"
            : "님의 최근 본 검색어예요"
    }
}

private struct SearchPopupDetailDestinationView: View {
    let store: StoreOf<SearchPopupDetailDestinationFeature>

    var body: some View {
        PopupDetailFeatureView(
            store: store.scope(state: \.content, action: \.content),
            isAdmin: false,
            hidesSystemTabBar: true,
            onSelectRelatedPopup: { userUuid, popup in
                store.send(.relatedPopupSelected(userUuid, popup))
            },
            onShowReviews: { reviews in
                store.send(.reviewsTapped(reviews))
            }
        )
    }
}

private struct SearchReviewDetailDestinationView: View {
    let store: StoreOf<ReviewFeature>

    var body: some View {
        ReviewFeatureView(store: store)
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
