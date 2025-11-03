//
//  PopupDetailView.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import SwiftUI
import Kingfisher

struct PopupDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) var openURL
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    @StateObject private var popupDetailViewModel = PopupDetailViewModel()
    let popup: Popup
    
//    init(popup: Popup) {
//        self.popup = popup
//        _popupDetailViewModel = StateObject(wrappedValue: PopupDetailViewModel())
//    }
    
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
                    }
                    .frame(height: 450) // 기본 높이
                    
                    VStack(alignment: .leading) {
                        
                        // MARK: - Title
                        Text(popup.name)
                            .ppStyleFont(.scdream(.bold, size: 20))
                            .foregroundStyle(Color.mainBlack)
                        
                        // MARK: - 임시 카운트 위치
                        HStack(spacing: 5) {
                            
                            if let viewCount = popup.viewCount {
                                Image("viewCount")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)
                                
                                Text("\(viewCount)")
                                    .ppStyleFont(.scdream(.regular, size: 9))
                            }
                            
                            if let favoriteCount = popup.favoriteCount {
                                Image("favoriteCount")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)
                                
                                Text("\(favoriteCount)")
                                    .ppStyleFont(.scdream(.regular, size: 9))
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
            
            HStack {
                
                MainOrangeButton(buttonTitle: "친구에게 공유하기",
                                 isReversed: true,
                                 height: 40) {
                    KakaoShareManager.shared.shareAppOnly(url: popup.imageUrlList[0],
                                                          title: popup.name,
                                                          description: popup.captionSummary,
                                                          imageUrl: popup.imageUrlList[0],
                                                          popupId: popup.popupUuid)
                }
                
                FavoriteButton(isFavorite: homeViewModel.isLiked(popup: popup),
                               buttonTitle: "찜하기",
                               buttonTitle2: "찜 취소하기",
                                 height: 40) {
                    // MARK: - 좋아요 토글 및 팝팡뷰 갱신
                    Task {
                        await homeViewModel.toggleLike(popup: popup)
                        await favoriteViewModel.loadFavoritePopups()
                    }
                }
            }
            .padding(.vertical, 10)
            .padding(.horizontal, .contentPadding)
            .background(Color.mainGray4)
            
        }
        
        // MARK: - onAppear 시점에 Kingfisher의 retriveImage API로 모든 사진 로드
        .onAppear {
            
            // MARK: - 캐싱 로직
            for urlString in popup.imageUrlList {
                guard let url = URL(string: urlString) else { continue }

                // ✅ 캐시 확인 후 없으면 다운로드
                ImageCache.default.retrieveImage(forKey: url.cacheKey) { result in
                    switch result {
                    case .success(let value):
                        if value.image == nil {
                            // 메모리/디스크에 캐시가 없을 경우 다운로드 실행
                            KingfisherManager.shared.retrieveImage(with: url) { _ in
                                print("✅ Preloaded \(url)")
                            }
                        } else {
                            print("✅ Already cached \(url)")
                        }
                    case .failure:
                        // 실패한 경우도 다시 다운로드 시도
                        KingfisherManager.shared.retrieveImage(with: url) { _ in
                            print("✅ Preloaded \(url)")
                        }
                    }
                }
            }
            
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
            }
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
                Text("운영 시간")
                    .foregroundStyle(Color.mainGray)
                HStack(spacing: 10) {
                    if let openTime = popup.openTime {
                        Text(openTime, formatter: DateFormatter.popupTimeFormat)
                    }
                    
                    if let closeTime = popup.closeTime {
                        Text("-")
                        Text(closeTime, formatter: DateFormatter.popupTimeFormat)
                    }
                }
            }
        }
        .font(.scdream(.regular, size: 15))
        .onAppear {
            print("✅ \(popup)")
        }
    }
 
}

// MARK: - 찜 버튼
private struct FavoriteButton: View {
    var isFavorite: Bool
    var buttonTitle: String
    var buttonTitle2: String
    var textColor: Color = .mainWhite
    var buttonColor: Color = .mainOrange

    var height: CGFloat = 40
    var action: () -> Void
    
    var body: some View {
        Button {
          action()
        } label: {
            Text(isFavorite ? buttonTitle2 : buttonTitle)
                .font(.scdream(.medium, size: 12))
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .foregroundStyle(Color.mainWhite)
                .background(isFavorite ?
                            Color.mainGray6 : Color.mainOrange)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .contentShape(RoundedRectangle(cornerRadius: 5))
        }
        .buttonStyle(PressableButtonStyle())
    }
}

// MARK: - 소셜 버튼
private struct SNSButton: View {
    let imageName: String
    let buttonTitle: String
    let action: () -> Void
    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(imageName)
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

#Preview {
    @Previewable @State var isFavorite: Bool = false
    VStack {
        SNSButton(imageName: "insta",
                  buttonTitle: "인스타그램") {
        }
        /*
        FavoriteButton(isFavorite: isFavorite,
                       buttonTitle: "찜하기",
                       buttonTitle2: "찜 취소하기") {
            isFavorite.toggle()
        }
         */
    }
    .padding(.horizontal, 20)
}

#Preview {
    PopupDetailView(popup: Popup.popupMock)
        .environmentObject(HomeViewModel(userUuid: "1234"))
        .environmentObject(FavoriteViewModel(userUuid: "1234"))
}
