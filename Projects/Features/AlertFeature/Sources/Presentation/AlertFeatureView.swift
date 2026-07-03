import ComposableArchitecture
import Core
import Domain
import DSKit
import Kingfisher
import SwiftUI

public struct AlertFeatureView: View {
    @Environment(\.dismiss) private var dismiss
    let store: StoreOf<AlertFeature>
    @State private var showKeywordLimitAlert = false

    private let segments = AlertFeature.AlertTab.allCases.map(\.title)

    public init(store: StoreOf<AlertFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(segments.indices, id: \.self) { index in
                    Button {
                        selectSegment(index)
                    } label: {
                        Text(segments[index])
                            .ppStyleFont(.scdream(.medium, size: 12))
                            .foregroundStyle(selectedIndex == index ? Color.mainOrange : Color.mainGray3)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                }
            }

            GeometryReader { geometry in
                let segmentWidth = geometry.size.width / CGFloat(segments.count)
                ZStack(alignment: .leading) {
                    Color.mainGray5.frame(height: 2)
                    Capsule()
                        .fill(Color.mainOrange)
                        .frame(width: segmentWidth, height: 4)
                        .offset(x: CGFloat(selectedIndex) * segmentWidth)
                        .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                }
            }
            .frame(height: 4)

            GeometryReader { geometry in
                HStack(spacing: 0) {
                    ActivityAlertView(
                        store: store,
                        onDeleteAll: {
                            store.send(.deleteAllPopupsTapped)
                        },
                        onDeletePopup: { popupUuid in
                            store.send(.deletePopupTapped(popupUuid))
                        },
                        onToggleLike: { popupUuid in
                            store.send(.toggleLikeTapped(popupUuid))
                        },
                        onSelectPopup: { popup in
                            store.send(.popupSelected(popup))
                        }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)

                    KeywordAlertView(
                        store: store,
                        onAddKeyword: { addKeywordIfAllowed($0) },
                        onRemoveKeyword: { keyword in
                            store.send(.removeKeywordTapped(keyword))
                        },
                        onRecentKeyword: { keyword in
                            addKeywordIfAllowed(keyword)
                        },
                        onRemoveRecentKeyword: { keyword in
                            store.send(.recentKeywordRemoved(keyword))
                        }
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
                .frame(width: geometry.size.width * CGFloat(segments.count), alignment: .leading)
                .offset(x: -CGFloat(selectedIndex) * geometry.size.width)
                .animation(.easeInOut(duration: 0.25), value: selectedIndex)
                .clipped()
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            handlePageDrag(value)
                        }
                )
            }

            if let message = store.errorMessage {
                Text(message)
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .padding(.horizontal, .contentPadding)
                    .padding(.vertical, 8)
            }
        }
        .ppBackNavigationBar(
            title: "알림",
            showsSeparator: false
        ) {
            dismiss()
        } trailing: {
            TrashButton(isEditing: store.isEditing) {
                store.send(.toggleEditing)
            }
        }
        .onAppear {
            store.send(.onAppear)
        }
        .alert("키워드 개수 제한", isPresented: $showKeywordLimitAlert) {
            Button("확인", role: .cancel) {}
        } message: {
            Text("키워드는 최대 5개 까지만 등록 가능합니다.")
        }
    }
}

private extension AlertFeatureView {
    var selectedIndex: Int {
        store.selectedTab.rawValue
    }

    func selectSegment(_ index: Int) {
        guard selectedIndex != index else { return }
        guard let tab = AlertFeature.AlertTab(rawValue: index) else { return }
        store.send(.tabChanged(tab))
    }

    func handlePageDrag(_ value: DragGesture.Value) {
        let horizontal = value.translation.width
        let vertical = value.translation.height
        guard abs(horizontal) > abs(vertical), abs(horizontal) > 50 else { return }

        let nextIndex = horizontal < 0
            ? min(selectedIndex + 1, segments.count - 1)
            : max(selectedIndex - 1, 0)
        selectSegment(nextIndex)
    }

    func addKeywordIfAllowed(_ keyword: String) {
        let trimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if store.keywords.count >= 5 {
            showKeywordLimitAlert = true
            return
        }

        store.send(.addKeywordTapped(trimmed))
    }
}

private struct ActivityAlertView: View {
    let store: StoreOf<AlertFeature>
    let onDeleteAll: () -> Void
    let onDeletePopup: (String) -> Void
    let onToggleLike: (String) -> Void
    let onSelectPopup: (Popup) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                HStack {
                    if store.isEditing {
                        Spacer()
                        Button(action: onDeleteAll) {
                            Text("전체 삭제")
                                .ppStyleFont(.scdream(.regular, size: 12))
                                .foregroundStyle(Color.mainBlack)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, .contentPadding)
                        .buttonStyle(PressableButtonStyle())
                    }
                }

                ForEach(Array(store.alertPopups.enumerated()), id: \.element.id) { index, popup in
                    AlertPopupCell(
                        popup: popup,
                        isLiked: popup.isFavorited,
                        onToggleLike: {
                            onToggleLike(popup.popupUuid)
                        }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectPopup(popup)
                    }
                    .overlay(alignment: .topTrailing) {
                        if store.isEditing {
                            Button {
                                onDeletePopup(popup.popupUuid)
                            } label: {
                                DSKitResource.image("removeBtn")
                                    .resizable()
                                    .frame(width: 40, height: 40)
                            }
                        }
                    }

                    if index != store.alertPopups.count - 1 {
                        Divider()
                            .frame(height: 1)
                            .background(Color.subWhite)
                    }
                }
            }
        }
        .padding(.horizontal, .contentPadding)
    }
}

private struct KeywordAlertView: View {
    let store: StoreOf<AlertFeature>
    let onAddKeyword: (String) -> Void
    let onRemoveKeyword: (Keyword) -> Void
    let onRecentKeyword: (String) -> Void
    let onRemoveRecentKeyword: (String) -> Void

    var body: some View {
        VStack {
            HStack(spacing: .contentPadding) {
                KeywordTextField(
                    placeholder: "알림 받고 싶은 키워드를 입력해주세요",
                    text: textBinding
                )

                Button {
                    onAddKeyword(store.keywordText)
                } label: {
                    DSKitResource.image("plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
            }

            VStack(spacing: 0) {
                ForEach(Array(store.keywords.enumerated()), id: \.1.id) { _, keyword in
                    HStack {
                        Text(keyword.keyword)
                            .ppStyleFont(.scdream(.medium, size: 12))

                        Spacer()

                        if store.isEditing {
                            Button {
                                onRemoveKeyword(keyword)
                            } label: {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 10, height: 10)
                                    .foregroundStyle(Color.mainGray)
                            }
                        }
                    }
                    .padding(.top, 17)
                    .padding(.horizontal, 5)

                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.mainGray7)
                        .padding(.top, 5)
                        .padding(.horizontal, 5)
                }
            }
            .padding(.top, 10)

            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(store.nickname)
                        .foregroundStyle(Color.mainOrange)
                        .font(.scdream(.bold, size: 12))

                    Text(store.recentKeywords.isEmpty ? "님의 최근 본 검색어가 없습니다" : "님의 최근 본 검색어예요")
                        .font(.scdream(.regular, size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                SearchFlowLayout {
                    ForEach(store.recentKeywords, id: \.self) { keyword in
                        SearchFlowButton(title: keyword) {
                            onRecentKeyword(keyword)
                        } onRemove: {
                            onRemoveRecentKeyword(keyword)
                        }
                        .padding(4)
                    }
                }
                .padding(.top, 15)
            }
            .padding(.top, 30)

            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, .contentPadding)
    }

    private var textBinding: Binding<String> {
        Binding(
            get: { store.keywordText },
            set: { store.send(.keywordTextChanged($0)) }
        )
    }
}

private struct AlertPopupCell: View {
    let popup: Popup
    let isLiked: Bool
    let onToggleLike: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .downSampled(.alertPopupCell)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133)
                    .clipped()

                VStack(alignment: .leading, spacing: 0) {
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

                    Spacer()

                    HStack(spacing: 5) {
                        Spacer()

                        DSKitResource.image("viewCount")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)

                        Text("\(popup.viewCount)")
                            .ppStyleFont(.scdream(.regular, size: 9))

                        Button(action: onToggleLike) {
                            HStack(spacing: 5) {
                                DSKitResource.image("favoriteCount")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)

                                Text("\(popup.favoriteCount)")
                                    .ppStyleFont(.scdream(.regular, size: 9))
                            }
                        }
                        .foregroundStyle(isLiked ? Color.mainOrange : Color.mainGray)
                    }
                }
                .padding(.leading, 18)
                .padding(.top, 10)

                Spacer()
            }
        }
        .padding(.vertical, 15)
    }
}

private struct TrashButton: View {
    var isEditing: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Text("완료")
                    .ppStyleFont(.scdream(.medium, size: 15))
                    .opacity(isEditing ? 1 : 0)

                Text("편집")
                    .ppStyleFont(.scdream(.medium, size: 15))
                    .opacity(isEditing ? 0 : 1)
            }
        }
        .buttonStyle(PressableButtonStyle())
        .animation(nil, value: isEditing)
    }
}
