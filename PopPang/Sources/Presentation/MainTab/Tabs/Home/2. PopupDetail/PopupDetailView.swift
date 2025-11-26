//
//  PopupDetailView.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import SwiftUI
import Kingfisher

struct PopupDetailView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    @StateObject private var popupDetailViewModel: PopupDetailViewModel
    let popup: Popup
    
    init(userUuid: String, popup: Popup) {
        _popupDetailViewModel = StateObject(wrappedValue: PopupDetailViewModel(userUuid: userUuid, popup: popup))
        self.popup = popup
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading) {
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
                    }
                    .frame(height: 450) // 기본 높이
                    
                    VStack(alignment: .leading, spacing: 0) {
                        
                        // MARK: - Title
                        
                        HStack {
                            Text(popup.name)
                                .ppStyleFont(.scdream(.bold, size: 20))
                                .foregroundStyle(Color.mainBlack)
                            
                            Button {
                                coordinator.push(.popupDetail(popupDetailViewModel.userUuid, .popupMock))
                            } label: {
                                Text("이런 팝업 어때요")
                            }
                        }
                        
                        Divider()
                            .background(Color.mainGray5)
                            .padding(.vertical, 15)
                        
                        // MARK: - Info
                        InfoView(popup: popup)
                        
                        Divider()
                            .background(Color.mainGray5)
                            .padding(.vertical, 15)
                        
                        // MARK: - Body
                        Text(popup.captionSummary)
                            .ppStyleFont(.scdream(.regular, size: 12),
                                       lineHeight: 1.4,
                                       letterSpacing: 0.02)
                        
                        Divider()
                            .background(Color.mainGray5)
                            .padding(.vertical, 15)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text("SNS / 홈페이지")
                                .font(.scdream(.medium, size: 15))
                                .frame(height: 21)
                            
                            SNSButton(imageName: "insta",
                                      buttonTitle: "인스타그램") {
                                openURL(URL(string: popup.instaPostUrl)!)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, .contentPadding)
                    
                    Spacer()
                        .frame(height: 200)
                }
            }
            .ignoresSafeArea()
            
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
            .padding(.vertical, 10)
            .padding(.horizontal, .contentPadding)
            .padding(.trailing, 10)
            .background(Color.mainGray4)
            
        }
        
        // MARK: - onAppear 시점에 Kingfisher의 retriveImage API로 모든 사진 로드
        .onAppear {
            
            // MARK: - 캐싱 로직
            popupDetailViewModel.prefetchImages(urls: popup.imageUrlList)
            
            // MARK: - 조회수 증가 로직
            Task {
                await popupDetailViewModel.increaseViewCount(popupUuid: popup.popupUuid)
            }
        }
        
        // MARK: - 디테일 화면에서만 뒤로가기 흰색으로
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // 커스텀 좌측
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
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
        
        // MARK: - 상단 그림자 추가
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [
                    Color.black.opacity(0.52),
                    Color.black.opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 150)       // 네비게이션바 + 상태바 높이
            .ignoresSafeArea(edges: .top)
        }
    }
}

// MARK: - 운영 정보 뷰
private struct InfoView: View {
    let popup: Popup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 20) {
                Text("운영 장소")
                    .foregroundStyle(Color.mainGray)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(popup.address)")
                    Text("\(popup.roadAddress)")
                }
            }
            
            HStack(spacing: 20) {
                Text("운영 날짜")
                    .foregroundStyle(Color.mainGray)
                HStack(spacing: 10) {
                    Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                    Text("-")
                    Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
                }
            }
            
            HStack(spacing: 20) {
                if let _ = popup.openTime, let _ = popup.closeTime {
                    Text("운영 시간")
                        .foregroundStyle(Color.mainGray)
                }
                HStack(spacing: 10) {
                    if let openTime = popup.openTime, let closeTime = popup.closeTime {
                        Text(openTime)
                        Text("-")
                        Text(closeTime)
                    }
                }
            }
        }
        .font(.scdream(.regular, size: 15))
    }
}

#Preview {
    PopupDetailView(userUuid: "", popup: Popup.popupMock2)
        .environmentObject(HomeViewModel(userUuid: "1234"))
        .environmentObject(FavoriteViewModel(userUuid: "1234"))
}
