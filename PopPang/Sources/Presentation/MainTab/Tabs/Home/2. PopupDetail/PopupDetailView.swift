//
//  PopupDetailView2.swift
//  PopPang
//
//  Created by 김동현 on 12/30/25.
//

import SwiftUI
import Kingfisher
import PopupView

struct PopupDetailView: View {
    
    @EnvironmentObject private var coordinator: Coordinator<MainRoute,
                                                            SheetRoute,
                                                            OverlayRoute,
                                                            FullScreenRoute>
    
    @EnvironmentObject private var rootViewModel: RootViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @StateObject private var popupDetailViewModel: PopupDetailViewModel
    @State private var showDeactivateAlert = false // 관리자 알림
    @State private var showingPopup = false        // 토스트 팝업
    private let popup: Popup
    private var isAdmin: Bool {
        rootViewModel.user?.role == "ADMIN"
    }
    private let segments: [String] = ["정보", "리뷰"]
    @State private var selectedSegment = 0
    
    // MARK: - init
    init(userUuid: String, popup: Popup) {
        _popupDetailViewModel = StateObject(wrappedValue: PopupDetailViewModel(userUuid: userUuid, popup: popup))
        self.popup = popup
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    ImageSliderView(popupDetailViewModel: popupDetailViewModel,
                                popup: popup, isAdmin: isAdmin, showDeactivateAlert: $showDeactivateAlert)

                    VStack(alignment: .leading, spacing: 0) {
                        TitleView(popup: popup)
                        
                        PopupDivider()
                        
                        InfoView(showingPopup: $showingPopup, popup: popup)
                        
                        PopupDivider(padding: 20)
                        
                        BodyView(popupDetailViewModel: popupDetailViewModel, popup: popup)

                    }
                    .padding(.top, 20)
                    .padding(.horizontal, .contentPadding)
                    
                    Spacer()
                        .frame(height: 130)
                }
            }
            .ignoresSafeArea()
            BottomTabBarView(popupDetailViewModel: popupDetailViewModel, popup: popup)
                .padding(.vertical, 10)
                .padding(.horizontal, .contentPadding)
                .padding(.trailing, 10)
                .background(Color.mainGray4)
        }
        .onAppear {
            // MARK: - 캐싱 로직
            popupDetailViewModel.prefetchImages(urls: popup.imageUrlList)
            
            // MARK: - 조회수 증가 로직
            Task {
                await popupDetailViewModel.increaseViewCount(popupUuid: popup.popupUuid)
            }
        }
        
        // MARK: - 디테일 화면에서만 뒤로가기 흰색으로
        .popupDetailNavigationBack {
            dismiss()
        }
        
        // MARK: - 상단 그림자 추가
        .topShadowGradient()
        
        // MARK: - 복사 토스트 팝업
        .popup(isPresented: $showingPopup) {
            Text("복사되었습니다.")
                .frame(width: 200, height: 30)
                .background(Color.mainWhite)
                // .background(Color(red: 0.85, green: 0.8, blue: 0.95))
                .cornerRadius(10.0)
        } customize: {
            $0
                .type(.floater())
                .position(.top)
                .appearFrom(.topSlide)
                .autohideIn(1.5)
                // .closeOnTap(false)          // 팝업 자체 눌러도 닫히기 X
                // .closeOnTapOutside(false)   // 팝업 주변 공간 눌러도 닫히기 X
        }
        
        // MARK: - 화면 이동시 토스트 팝업 비활성화
        .onChange(of: coordinator.paths) { _, _ in
            showingPopup = false       // push/pop 이동 시
        }
        
        .alert("팝업 비활성화", isPresented: $showDeactivateAlert) {
            Button("취소", role: .cancel) {}
            
            Button("비활성화", role: .destructive) {
                Task {
                    await popupDetailViewModel.deactivatePopup(userUuid: rootViewModel.user?.userUuid ?? "", popupUuid: popup.popupUuid)
                    
                    await MainActor.run {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("정말로 이 팝업을 비활성화하시겠습니까?\n비활성화된 팝업은 사용자에게 노출되지 않습니다.")
        }
    }
}

// MARK: - ImageSlider
private struct ImageSliderView: View {
    @ObservedObject var popupDetailViewModel: PopupDetailViewModel
    let popup: Popup
    let isAdmin: Bool
    @Binding var showDeactivateAlert: Bool
    
    var body: some View {
        GeometryReader { geo in
            let offset = geo.frame(in: .global).minY

            TabView {
                ForEach(popup.imageUrlList, id: \.self) { imageUrl in
                    KFImage(URL(string: imageUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width,
                               height: 450 + (offset > 0 ? offset : 0)) // 전체 TabView 높이 늘림
                        .clipped()
                }
            }
            .tabViewStyle(.page)
            // 여기서 TabView 자체에 offset 적용
            .frame(height: 450 + (offset > 0 ? offset : 0))
            .offset(y: (offset > 0 ? -offset : 0))
            .overlay(alignment: .bottomLeading) {
                Text("\(popupDetailViewModel.popup.viewCount)명이 봤어요")
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainBlack)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 24)
                    .background(Color.white.opacity(0.8))
                    .cornerRadius(50)
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
                    .applyShadow(color: Color.subBlack,
                                 alpha: 0.05,
                                 x: 0,
                                 y: 4,
                                 blur: 4)
            }
            .overlay(alignment: .bottomTrailing) {
                // MARK: - 관리자 버튼
                AdminDisablePopupButton(isAdmin: isAdmin) {
                    print("버튼 눌림")
                    showDeactivateAlert = true
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
        }
        .frame(height: 450) // 기본 높이
    }
}

// MARK: - Title
private struct TitleView: View {
    let popup: Popup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Title
            HStack {
                Text(popup.name)
                    .ppStyleFont(.scdream(.bold, size: 20))
                    .foregroundStyle(Color.mainBlack)
            }
            
            PopupCategoryTag(text: popup.recommendList[0])
                .padding(.top, 5)
        }
    }
}

// MARK: - Info
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
                    Text("\(popup.roadAddress)")
                }
                .ppStyleFont(.scdream(.regular, size: 15))
                .foregroundStyle(Color.mainBlack)
                
                Button {
                    UIPasteboard.general.string = popup.roadAddress
                    showingPopup = true
                } label: {
                    Image("copy")
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
                if let _ = popup.openTime, let _ = popup.closeTime {
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

// MARK: - Body
private struct BodyView: View {
    @Environment(\.openURL) var openURL
    @ObservedObject var popupDetailViewModel: PopupDetailViewModel
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    let popup: Popup
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - 본문
            Text(popup.captionSummary)
                .ppStyleFont(.scdream(.regular, size: 15),
                           lineHeight: 1.6,
                           letterSpacing: 0.02)
            
            PopupDivider(padding: 20)
            
            // MARK: - 리뷰
            HStack {
                Text("리뷰")
                    .font(.scdream(.medium, size: 15))
                
                Spacer()
                
                Button {
                    coordinator.push(.reviewDetail(popupDetailViewModel.mockReview))
                } label: {
                    Image("navigationButton")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
            }
            
            LazyVStack {
                ForEach(popupDetailViewModel.mockReview[0...2]) { review in
                    ReviewCell(nickname: review.nickname, info: review.info, starCount: review.starCount)
                }
            }
            .padding(.top, 10)
            
            PopupDivider(padding: 20)
            
            // MARK: - SNS/홈페이지
            Text("SNS / 홈페이지")
                .font(.scdream(.medium, size: 15))
                .frame(height: 21)
            
            SNSButton(imageName: "insta",
                      buttonTitle: "인스타그램") {
                openURL(URL(string: popup.instaPostUrl)!)
            }
            .padding(.top, 8)
            
            PopupDivider(padding: 20)
            
            // MARK: - 추천 팝업
            Text("이런 팝업은 어때?")
                .ppStyleFont(.scdream(.medium, size: 15))
            
            RecommendPopupScrollView()
                .environmentObject(popupDetailViewModel)
                .padding(.top, 20)
        }
    }
}

// MARK: - BottomTabBar
private struct BottomTabBarView: View {
    @ObservedObject var popupDetailViewModel: PopupDetailViewModel
    let popup: Popup
    var body: some View {
        HStack(spacing: 20) {
            
            MainOrangeButton(buttonTitle: "친구에게 공유하기",
                             isReversed: false,
                             height: 40) {
                KakaoShareManager.shared.shareAppOnly(
                                                      title: popup.name,
                                                      description: popup.captionSummary,
                                                      imageUrl: popup.imageUrlList[0],
                                                      popupId: popup.popupUuid)
            }
            
            VStack(spacing: 2) {
                FavoriteButton(isFavorite: popupDetailViewModel.popup.isFavorited,
                               buttonImage: "favorite",
                               buttonImage2: "favorite_fill",
                               height: 30) {
                    
                    // MARK: - 좋아요 토글 및 팝팡뷰 갱신
                    Task {
                        await popupDetailViewModel.toggleLike()
                    }
                }
                
                let favoriteCount = popupDetailViewModel.popup.favoriteCount
                Text("\(favoriteCount)")
                    .ppStyleFont(.scdream(.regular, size: 12))
            }
        }
    }
}

// MARK: - PopupDivider
private struct PopupDivider: View {
    var padding: CGFloat = 15

    var body: some View {
        Divider()
            .background(Color.mainGray5)
            .padding(.vertical, padding)
    }
}

// MARK: - 이런 팝업은 어때
private struct RecommendPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @EnvironmentObject private var popupDetailViewModel: PopupDetailViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack {
                ForEach(popupDetailViewModel.relatedPopupList, id: \.self) { popup in
                    RecommendPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popupDetailViewModel.userUuid, popup))
                        }
                }
            }
        }
    }
}

// MARK: - 이런 팝업은 어때 Cell
struct RecommendPopupCell: View {
    let popup: Popup
    let cellWidth: CGFloat = 115
    let cellHeight: CGFloat = 162
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            KFImage(URL(string: popup.imageUrlList[0]))
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: cellWidth, height: cellWidth)
                .clipped()
            
            Text(popup.roadAddress.shortAddress)
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainBlack)
                .padding(.top, 10)
            
            Text(popup.name)
                .font(.scdream(.medium, size: 12) )
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.top, 5)
        }
        .frame(width: cellWidth, height: cellHeight)
    }
}

// MARK: - 관리자 삭제 버튼
struct AdminDisablePopupButton: View {
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

// MARK: - ViewModifier
struct PopupDetailNavigationBackModifier: ViewModifier {
    let onBack: () -> Void
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // 커스텀 좌측
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        onBack()
                    } label: {
                        Image("backButton")
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)
                            .foregroundStyle(Color.subWhite)
                    }
                    .applyShadow(color: .mainBlack, alpha: 0.25, x: 0, y: 1, blur: 3)
                }
            }
    }
}

struct TopShadowGradientModifier: ViewModifier {
    var height: CGFloat = 100
    var opacity: Double = 0.52
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [
                        Color.black.opacity(opacity),
                        Color.black.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: height)       // 네비게이션바 + 상태바 높이
                .ignoresSafeArea(edges: .top)
            }
    }
}

extension View {
    func popupDetailNavigationBack(onBack: @escaping () -> Void) -> some View {
        self.modifier(PopupDetailNavigationBackModifier(onBack: onBack))
    }
    
    func topShadowGradient(height: CGFloat = 100, opacity: Double = 0.52) -> some View {
        self.modifier(TopShadowGradientModifier(height: height, opacity: opacity))
    }
}

#Preview {
    PopupDetailView(userUuid: "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13", popup: Popup.popupMock2)
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>())
        .environmentObject(PopupDetailViewModel(userUuid: "4c3b9a55-f4ee-42cc-9bd2-82a5c811db13", popup: .popupMock))
        .environmentObject(RootViewModel())
}

// MARK: - 리뷰 셀
struct ReviewCell: View {
    let nickname: String
    let info: String
    let starCount: Int
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - Header(별점 + 신고)
            HStack(spacing: 3) {
                ForEach(0..<starCount, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .resizable()
                        .frame(width: 15, height: 15)
                }
                
                Spacer()
                
                Text("2026.01.03")
                    .font(.scdream(.light, size: 12))
                
                Text("|")
                    .font(.scdream(.light, size: 12))
                
                Text("신고")
                    .font(.scdream(.light, size: 12))
            }
            
            // MARK: - 닉네임
            Text("홍길동")
                .font(.scdream(.medium, size: 12))
                .padding(.top, 10)
            
            // MARK: - 리뷰
            Text("정말 재미있어요!")
                .font(.scdream(.light, size: 12))
                .padding(.top, 10)
        }
        .padding(10)
        .background(.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

// MARK: - 리뷰 상세 화면
struct ReviewDetailView: View {
    // @ObservedObject var popupDetailViewModel: PopupDetailViewModel
    let reviewList: [Review]
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(reviewList) { review in
                    ReviewCell(nickname: review.nickname, info: review.info, starCount: review.starCount)
                }
            }
            .padding(.top, 20)
            .padding(.horizontal, .contentPadding)
        }
    }
}

#Preview {
    let mockReview: [Review] = [
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 5),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 4),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 3),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 5),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 4),
        Review(nickname: "홍길동", info: "정말 재미있어요!", starCount: 3)
    ]
    ReviewDetailView(reviewList: mockReview)
    // ReviewCell()
}
