import Core
import Domain
import DSKit
import Kingfisher
import SwiftUI
import UIKit

public struct PopupDetailFeatureView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var compound: PopupDetailFeatureCompound
    @State private var showDeactivateAlert = false
    @State private var showingPopup = false

    private let isAdmin: Bool
    private let onShowReviews: ([Review]) -> Void

    public init(
        userUuid: String = "demo-user",
        popup: Popup = .popupMock,
        isAdmin: Bool = false,
        onSelectRelatedPopup: @escaping (String, Popup) -> Void = { _, _ in },
        onDeactivateComplete: @escaping () -> Void = {},
        onShowReviews: @escaping ([Review]) -> Void = { _ in }
    ) {
        _compound = State(
            wrappedValue: PopupDetailFeatureCompound(
                userUuid: userUuid,
                popup: popup,
                onSelectRelatedPopup: onSelectRelatedPopup,
                onDeactivateComplete: onDeactivateComplete
            )
        )
        self.isAdmin = isAdmin
        self.onShowReviews = onShowReviews
    }

    public var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ImageSliderView(
                        popup: compound.state.popup,
                        isAdmin: isAdmin,
                        showDeactivateAlert: $showDeactivateAlert
                    )

                    VStack(alignment: .leading, spacing: 0) {
                        TitleView(popup: compound.state.popup)

                        PopupDivider()

                        InfoView(showingPopup: $showingPopup, popup: compound.state.popup)

                        PopupDivider(padding: 20)

                        BodyView(
                            popup: compound.state.popup,
                            reviews: Review.mock,
                            relatedPopupList: compound.state.relatedPopupList,
                            onShowReviews: onShowReviews,
                            onSelectRelatedPopup: { popup in
                                compound.send(.relatedPopupTapped(popup))
                            }
                        )
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, .contentPadding)

                    Spacer()
                        .frame(height: 130)
                }
            }
            .ignoresSafeArea()

            BottomTabBarView(
                popup: compound.state.popup,
                onShare: {
                    KakaoShareManager.shared.shareAppOnly(
                        title: compound.state.popup.name,
                        description: compound.state.popup.captionSummary,
                        imageUrl: compound.state.popup.imageUrlList.first ?? "",
                        popupId: compound.state.popup.popupUuid
                    )
                },
                onToggleLike: {
                    compound.send(.toggleLike)
                }
            )
            .padding(.vertical, 10)
            .padding(.horizontal, .contentPadding)
            .padding(.trailing, 10)
            .background(Color.mainGray4)
        }
        .onAppear {
            compound.send(.onAppear)
        }
        .popupDetailNavigationBack {
            dismiss()
        }
        .topShadowGradient()
        .overlay(alignment: .top) {
            if showingPopup {
                Text("복사되었습니다.")
                    .frame(width: 200, height: 30)
                    .background(Color.mainWhite)
                    .cornerRadius(10.0)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onChange(of: showingPopup) { _, isPresented in
            guard isPresented else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showingPopup = false
                }
            }
        }
        .alert("팝업 비활성화", isPresented: $showDeactivateAlert) {
            Button("취소", role: .cancel) {}

            Button("비활성화", role: .destructive) {
                compound.send(.deactivatePopup)
            }
        } message: {
            Text("정말로 이 팝업을 비활성화하시겠습니까?\n비활성화된 팝업은 사용자에게 노출되지 않습니다.")
        }
    }
}

private struct ImageSliderView: View {
    let popup: Popup
    let isAdmin: Bool
    @Binding var showDeactivateAlert: Bool

    var body: some View {
        GeometryReader { geo in
            let offset = geo.frame(in: .global).minY

            ZStack(alignment: .bottom) {
                TabView {
                    ForEach(popup.imageUrlList, id: \.self) { imageUrl in
                        KFImage(URL(string: imageUrl))
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(
                                width: geo.size.width,
                                height: 450 + (offset > 0 ? offset : 0)
                            )
                            .clipped()
                    }
                }
                .tabViewStyle(.page)
                .frame(height: 450 + (offset > 0 ? offset : 0))
                .offset(y: (offset > 0 ? -offset : 0))

                HStack(alignment: .bottom) {
                    Text("\(popup.viewCount)명이 봤어요")
                        .ppStyleFont(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 24)
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(50)
                        .applyShadow(color: Color.subBlack, alpha: 0.05, x: 0, y: 4, blur: 4)

                    Spacer()

                    AdminDisablePopupButton(isAdmin: isAdmin) {
                        showDeactivateAlert = true
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .frame(width: geo.size.width, height: 450, alignment: .top)
        }
        .frame(height: 450)
    }
}

private struct TitleView: View {
    let popup: Popup

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(popup.name)
                    .ppStyleFont(.scdream(.bold, size: 20))
                    .foregroundStyle(Color.mainBlack)
            }

            if let tag = popup.recommendList.first {
                PopupCategoryTag(text: tag)
                    .padding(.top, 5)
            }
        }
    }
}

private struct InfoView: View {
    @Binding var showingPopup: Bool
    let popup: Popup

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 20) {
                Text("운영 장소")
                    .ppStyleFont(.scdream(.regular, size: 15))
                    .foregroundStyle(Color.mainGray)

                VStack(alignment: .leading, spacing: 8) {
                    Text(popup.roadAddress)
                }
                .ppStyleFont(.scdream(.regular, size: 15))
                .foregroundStyle(Color.mainBlack)

                Button {
                    UIPasteboard.general.string = popup.roadAddress
                    showingPopup = true
                } label: {
                    DSKitResource.image("copy")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color.mainGray2)
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(PressableButtonStyle())
                .padding(.leading, -15)
            }

            HStack(spacing: 20) {
                Text("운영 날짜")
                    .ppStyleFont(.scdream(.regular, size: 15))
                    .foregroundStyle(Color.mainGray)
                HStack(spacing: 10) {
                    Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                    Text("-")
                    Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                }
                .ppStyleFont(.scdream(.regular, size: 15))
                .foregroundStyle(Color.mainBlack)
            }

            HStack(spacing: 20) {
                if popup.openTime != nil, popup.closeTime != nil {
                    Text("운영 시간")
                        .ppStyleFont(.scdream(.regular, size: 15))
                        .foregroundStyle(Color.mainGray)
                }
                HStack(spacing: 10) {
                    if let openTime = popup.openTime, let closeTime = popup.closeTime {
                        Text(openTime)
                        Text("-")
                        Text(closeTime)
                    }
                }
                .ppStyleFont(.scdream(.regular, size: 15))
                .foregroundStyle(Color.mainBlack)
            }
        }
        .font(.scdream(.regular, size: 15))
    }
}

private struct BodyView: View {
    @Environment(\.openURL) private var openURL

    let popup: Popup
    let reviews: [Review]
    let relatedPopupList: [Popup]
    let onShowReviews: ([Review]) -> Void
    let onSelectRelatedPopup: (Popup) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(popup.captionSummary)
                .ppStyleFont(
                    .scdream(.regular, size: 15),
                    lineHeight: 1.6,
                    letterSpacing: 0.02
                )

            PopupDivider(padding: 20)

            // ReviewPreviewSection(reviews: reviews) {
            //     onShowReviews(reviews)
            // }
            //
            // PopupDivider(padding: 20)

            Text("SNS / 홈페이지")
                .font(.scdream(.medium, size: 15))
                .frame(height: 21)

            SNSButton(
                imageName: "insta",
                buttonTitle: "인스타그램"
            ) {
                guard let url = URL(string: popup.instaPostUrl) else { return }
                openURL(url)
            }
            .padding(.top, 8)
            .padding(.bottom, relatedPopupList.isEmpty ? 40 : 0)

            if !relatedPopupList.isEmpty {
                PopupDivider(padding: 20)

                Text("이런 팝업은 어때?")
                    .ppStyleFont(.scdream(.medium, size: 15))

                RecommendPopupScrollView(
                    relatedPopupList: relatedPopupList,
                    onSelectRelatedPopup: onSelectRelatedPopup
                )
                .padding(.top, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

private struct BottomTabBarView: View {
    let popup: Popup
    let onShare: () -> Void
    let onToggleLike: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            MainOrangeButton(
                buttonTitle: "친구에게 공유하기",
                isReversed: false,
                height: 40,
                action: onShare
            )

            VStack(spacing: 2) {
                FavoriteButton(
                    isFavorite: popup.isFavorited,
                    buttonImage: "favorite",
                    buttonImage2: "favorite_fill",
                    height: 30,
                    action: onToggleLike
                )

                Text("\(popup.favoriteCount)")
                    .ppStyleFont(.scdream(.regular, size: 12))
            }
        }
    }
}

private struct PopupDivider: View {
    var padding: CGFloat = 15

    var body: some View {
        Divider()
            .background(Color.mainGray5)
            .padding(.vertical, padding)
    }
}

private struct ReviewPreviewSection: View {
    let reviews: [Review]
    let onShowAllReviews: () -> Void

    var body: some View {
        HStack {
            Text("리뷰 \(reviews.count)개")
                .font(.scdream(.medium, size: 15))

            Spacer()

            Button {
                onShowAllReviews()
            } label: {
                DSKitResource.image("navigationButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            }
        }

        LazyVStack {
            ForEach(Array(reviews.prefix(3))) { review in
                ReviewCell(
                    nickname: review.nickname,
                    review: review.info,
                    starCount: review.starCount
                )
            }
        }
        .padding(.top, 20)
    }
}

private struct ReviewCell: View {
    let nickname: String
    let review: String
    let starCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 3) {
                ForEach(0..<starCount, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 12, height: 12)
                        .foregroundStyle(Color.mainOrange)
                }

                Spacer()

                Text("2026.01.03")
                    .font(.scdream(.light, size: 12))

                Text("|")
                    .font(.scdream(.light, size: 12))

                Text("신고")
                    .font(.scdream(.light, size: 12))
            }

            Text(nickname)
                .font(.scdream(.medium, size: 12))
                .padding(.top, 10)

            Text(review)
                .font(.scdream(.light, size: 12))
                .padding(.top, 10)
        }
        .padding(10)
        .background(.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

private struct RecommendPopupScrollView: View {
    let relatedPopupList: [Popup]
    let onSelectRelatedPopup: (Popup) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(alignment: .top) {
                ForEach(relatedPopupList, id: \.self) { popup in
                    RecommendPopupCell(popup: popup)
                        .onTapGesture {
                            onSelectRelatedPopup(popup)
                        }
                }
            }
        }
        .frame(height: RecommendPopupCell.cellHeight)
    }
}

private struct RecommendPopupCell: View {
    let popup: Popup
    static let cellHeight: CGFloat = 182
    private let cellWidth: CGFloat = 115

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            KFImage(URL(string: popup.imageUrlList.first ?? ""))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cellWidth, height: cellWidth)
                .clipped()

            Text(popup.roadAddress.shortAddress)
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 10)

            Text(popup.name)
                .font(.scdream(.medium, size: 12))
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 5)
        }
        .frame(width: cellWidth, height: Self.cellHeight, alignment: .top)
    }
}

private struct FavoriteButton: View {
    var isFavorite: Bool
    var buttonImage: String
    var buttonImage2: String
    var textColor: Color = .mainWhite
    var buttonColor: Color = .mainOrange
    var height: CGFloat = 40
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            DSKitResource.image(isFavorite ? buttonImage2 : buttonImage)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 25, height: 25)
                .foregroundStyle(isFavorite ? Color.mainOrange : Color.black)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct SNSButton: View {
    let imageName: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                DSKitResource.image(imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 12, height: 12)

                Text(buttonTitle)
                    .ppStyleFont(.scdream(.medium, size: 10))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .foregroundStyle(Color.mainGray6)
            .background(Color.mainGray5)
            .cornerRadius(17)
        }
        .buttonStyle(PressableButtonStyle())
    }
}

private struct AdminDisablePopupButton: View {
    let isAdmin: Bool
    let action: () -> Void

    var body: some View {
        if isAdmin {
            Button(action: action) {
                Text("팝업 비활성화")
                    .foregroundStyle(Color.mainRed)
                    .ppStyleFont(.scdream(.bold, size: 17))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.8))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.mainRed, lineWidth: 1)
                    )
            }
            .buttonStyle(PressableButtonStyle())
        }
    }
}

private struct PopupDetailNavigationBackModifier: ViewModifier {
    let onBack: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onBack()
                    } label: {
                        DSKitResource.image("backButton")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Color.subWhite)
                            // .foregroundStyle(Color.mainBlack)
                    }
                    .applyShadow(color: .mainBlack, alpha: 0.25, x: 0, y: 1, blur: 3)
                }
            }
    }
}

private struct TopShadowGradientModifier: ViewModifier {
    var height: CGFloat = 100
    var opacity: Double = 0.52

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color.black.opacity(opacity),
                        Color.black.opacity(0.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: height)
                .ignoresSafeArea(edges: .top)
            }
    }
}

private extension View {
    func popupDetailNavigationBack(onBack: @escaping () -> Void) -> some View {
        modifier(PopupDetailNavigationBackModifier(onBack: onBack))
    }

    func topShadowGradient(height: CGFloat = 100, opacity: Double = 0.52) -> some View {
        modifier(TopShadowGradientModifier(height: height, opacity: opacity))
    }
}
