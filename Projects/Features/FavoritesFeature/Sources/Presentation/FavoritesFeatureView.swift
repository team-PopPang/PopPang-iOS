import ComposableArchitecture
import Core
import Domain
import DSKit
import Kingfisher
import SwiftUI

public struct FavoritesFeatureView: View {
    let store: StoreOf<FavoritesFeature>

    private let segments: [String] = ["찜리스트", "찜캘린더"]

    public init(store: StoreOf<FavoritesFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            CustomNavigationBar {
                Text("찜")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)
                    .frame(height: 45)

                Spacer()

                IconButton {
                    store.send(.alertTapped)
                }
            }

            SegmentedControlView(
                segments: segments,
                views: [
                    FavoriteListView(
                        popups: store.favoritePopups,
                        isLoading: store.isLoading,
                        errorMessage: store.errorMessage,
                        onBrowsePopups: {
                            store.send(.browsePopupsTapped)
                        },
                        onSelectPopup: { popup in
                            store.send(.popupSelected(popup))
                        },
                        onToggleLike: { popup in
                            store.send(.toggleLike(popup))
                        }
                    ),
                    FavoriteCalendarView(
                        selectedDate: store.selectedDate,
                        selectedPopups: store.selectedPopups,
                        popupEventCounts: store.popupEventCounts,
                        isLoading: store.isLoading,
                        errorMessage: store.errorMessage,
                        onDateSelected: { date in
                            store.send(.dateSelected(date))
                        },
                        onSelectPopup: { popup in
                            store.send(.popupSelected(popup))
                        },
                        onToggleLike: { popup in
                            store.send(.toggleLike(popup))
                        }
                    )
                ],
                background: .mainGray3,
                foreground: .mainOrange
            )

            Spacer()
        }
        .onAppear {
            store.send(.onAppear)
        }
    }
}

private struct FavoriteListView: View {
    let popups: [Popup]
    let isLoading: Bool
    let errorMessage: String?
    let onBrowsePopups: () -> Void
    let onSelectPopup: (Popup) -> Void
    let onToggleLike: (Popup) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if let errorMessage {
                Text(errorMessage)
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }

            if !popups.isEmpty {
                ListGridPopupScrollView(
                    popups: popups,
                    onSelectPopup: onSelectPopup,
                    onToggleLike: onToggleLike
                )
                .padding(.top, 24)
            } else if !isLoading {
                VStack {
                    Text("찜한 팝업스토어가 없어요")
                        .ppStyleFont(.scdream(.medium, size: 15))

                    Button {
                        onBrowsePopups()
                    } label: {
                        Text("팝업스토어 구경가기")
                            .ppStyleFont(.scdream(.medium, size: 12))
                            .frame(width: 206, height: 32)
                            .foregroundStyle(Color.subWhite)
                            .background(Color.mainOrange)
                            .cornerRadius(5)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, .contentPadding)
    }
}

private struct ListGridPopupScrollView: View {
    let popups: [Popup]
    let onSelectPopup: (Popup) -> Void
    let onToggleLike: (Popup) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15),
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(popups) { popup in
                    VStack(alignment: .leading) {
                        ListPopupCell(
                            popup: popup,
                            onToggleLike: {
                                onToggleLike(popup)
                            }
                        )
                        .onTapGesture {
                            onSelectPopup(popup)
                        }
                    }
                }
            }
        }
    }
}

private struct ListPopupCell: View {
    let popup: Popup
    let onToggleLike: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 217, alignment: .center)

                GeometryReader { geo in
                    KFImage(URL(string: popup.imageUrlList.first ?? ""))
                        .placeholder {
                            Rectangle()
                                .fill(Color.mainGray3)
                                .frame(height: 217)
                        }
                        .downSampled(.favoriteListCell)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: 217, alignment: .center)
                        .clipped()
                }
                .overlay(alignment: .topTrailing) {
                    BookmarkButton(isLiked: popup.isFavorited, info: .stroke) {
                        onToggleLike()
                    }
                    .padding(10)
                    .applyShadow(color: .mainBlack, alpha: 0.25, x: 0, y: 1, blur: 3)
                }
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
        .contentShape(Rectangle())
    }
}

private struct FavoriteCalendarView: View {
    let selectedDate: Date
    let selectedPopups: [Popup]
    let popupEventCounts: [Date: Int]
    let isLoading: Bool
    let errorMessage: String?
    let onDateSelected: (Date) -> Void
    let onSelectPopup: (Popup) -> Void
    let onToggleLike: (Popup) -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                CustomCalendar(
                    eventCounts: popupEventCounts,
                    onDateSelected: onDateSelected
                )
                .padding(.top, 24)
                .padding(.horizontal, 15)

                FavoriteCalendarPopupListView(
                    date: selectedDate,
                    popups: selectedPopups,
                    isLoading: isLoading,
                    errorMessage: errorMessage,
                    onSelectPopup: onSelectPopup,
                    onToggleLike: onToggleLike
                )
                .padding(.horizontal, 15)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .mask(
                            LinearGradient(
                                gradient: Gradient(colors: [.black, .clear, .clear, .clear]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .applyShadow(
                            color: .black,
                            alpha: 0.05,
                            x: 0,
                            y: -4,
                            blur: 8
                        )
                )
                .padding(.top, 20)

                Spacer()
            }
        }
    }
}

private struct FavoriteCalendarPopupListView: View {
    let date: Date
    let popups: [Popup]
    let isLoading: Bool
    let errorMessage: String?
    let onSelectPopup: (Popup) -> Void
    let onToggleLike: (Popup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(formattedDate(date))
                    .ppStyleFont(.scdream(.bold, size: 12))
                    .foregroundStyle(Color.mainBlack)
                Spacer()
            }
            .padding(.top, 20)

            if let errorMessage {
                Text(errorMessage)
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainRed)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 12)
            }

            if popups.isEmpty && !isLoading {
                Text("선택한 날짜에 팝업이 없습니다")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 24)
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 10) {
                        ForEach(Array(popups.enumerated()), id: \.element.id) { index, popup in
                            FavoriteCalendarPopupCell(
                                popup: popup,
                                onToggleLike: {
                                    onToggleLike(popup)
                                }
                            )
                            .onTapGesture {
                                onSelectPopup(popup)
                            }

                            if index != popups.count - 1 {
                                Divider()
                                    .frame(height: 1)
                                    .background(Color.subWhite)
                            }
                        }
                    }
                }
                .padding(.top, 20)
            }
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let dayFormatter = DateFormatter()
        dayFormatter.locale = Locale(identifier: "ko_KR")
        dayFormatter.dateFormat = "d일 (E)"
        return dayFormatter.string(from: date)
    }
}

private struct FavoriteCalendarPopupCell: View {
    let popup: Popup
    let onToggleLike: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                KFImage(URL(string: popup.imageUrlList.first ?? ""))
                    .placeholder {
                        Rectangle()
                            .fill(Color.mainGray3)
                            .frame(width: 106, height: 133)
                    }
                    .downSampled(.favoriteCalendarCell)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133, alignment: .center)
                    .clipped()

                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)

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

                        Button {
                            onToggleLike()
                        } label: {
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
                        .foregroundStyle(popup.isFavorited ? Color.mainOrange : Color.mainGray)
                    }
                }
                .padding(.leading, 18)
                .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }
}

private struct BookmarkButton: View {
    enum Info {
        case fill
        case stroke
    }

    var isLiked: Bool
    var info: Info
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            switch info {
            case .fill:
                DSKitResource.image(isLiked ? "favorite_fill" : "favorite")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            case .stroke:
                DSKitResource.image(isLiked ? "favorite_fill" : "favorite")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .foregroundStyle(isLiked ? Color.mainOrange : Color.subWhite)
            }
        }
    }
}
