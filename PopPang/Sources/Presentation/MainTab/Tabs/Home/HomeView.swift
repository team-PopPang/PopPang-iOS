//
//  HomeView.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI
import Kingfisher

struct HomeView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @State private var searchText = ""
    @State private var selectRegion: String? = nil
    @State private var selectSort: String? = nil
    
    // MARK: - 광고뷰 테스트
    @State private var hasSeenPopup: Bool = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                
                // MARK: - Search & Alert
                CustomNavigationBar {
                    SearchTextField(placeholder: "궁금한 장소를 검색해보세요",
                                    text: $searchText)
                    .disabled(true)
                    .overlay {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                coordinator.presentSheet(.search(uuid: rootViewModel.user?.userUuid ?? ""))
                            }
                    }
                    
                    IconButton {
                        print("알림 버튼 클릭됨")
                        coordinator.push(.alert(uuid: rootViewModel.user?.userUuid ?? ""))
                    }
                    .padding(.leading, 15)
                }
                 .padding(.bottom, 15)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // MARK: - Best Popup
                        BestPopupScrollView(viewModel: homeViewModel)
                        
                        // MARK: - Coming Popup
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("COMING SOON")
                                    .font(.scdream(.medium, size: 11))
                                    .foregroundStyle(Color.mainOrange)
                                
                                Text("곧 생기는 팝업")
                                    .font(.scdream(.bold, size: 15))
                                    .foregroundStyle(Color.mainBlack)
                            }
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Image("navigationButton")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            }
                            .padding(.trailing, .contentPadding)
                        }
                        .padding(.top, 50)
                        ComingPopupScrollView(viewModel: homeViewModel)
                        
                        // MARK: - DropDownView
                        HStack {
                            DropDownView(options: [
                                            "전체",
                                            "서울",
                                            "부산",
                                            "진주"
                                         ],
                                         anchor: .bottom,
                                         maxWidth: 90,
                                         selection: $selectRegion,
                                         overlay: false,
                                         pickedFont: .scdream(.medium, size: 17),
                                         detailFont: .scdream(.medium, size: 17)
                            )
                            .padding(.leading, -10)
                            
                            Spacer()
                            
                            DropDownView(options: [
                                            "찜순",
                                            "가까운순",
                                         ],
                                         anchor: .bottom,
                                         maxWidth: 90,
                                         cornerRadius: 17,
                                         stroke: .mainGray5,
                                         imgSize: 10,
                                         imgColor: .mainGray2,
                                         selection: $selectSort,
                                         overlay: true,
                                         pickedFont: .scdream(.light, size: 10),
                                         detailFont: .scdream(.light, size: 10)
                                        
                            )
                        }
                        .zIndex(1)
                        .padding(.top, 50)
                        .padding(.trailing, .contentPadding)
                        
                        // MARK: - GridView
                        GridPopupScrollView(viewModel: homeViewModel)
                        .padding(.top, 15)
                        .padding(.trailing, .contentPadding)
                        
                        // Spacer()
                    }
                    .padding(.bottom, 50)
                }
                .padding(.leading, .contentPadding)
            }
        }
        .onAppear {
            if !hasSeenPopup {
                /*
                coordinator.presentOverlay(overlay: .notice(title: "베타 업데이트 내용",
                                                            content: Constants.BetaNotice.beta_1012))
                 */

                hasSeenPopup = true
            }
        }
        .fullScreenCover(item: $coordinator.sheet) { route in
            coordinator.buildView(for: route)
        }
        .withoutAnimation()
    }
}

// MARK: - Best Popup
private struct BestPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var viewModel: HomeViewModel
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(viewModel.bestPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    BestPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
                        }
                }
            }
            .padding(.trailing, .contentPadding)
        }
    }
}

private struct BestPopupCell: View {
    let popup: Popup
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            GeometryReader { geo in
                // MARK: - 이미지
                KFImage(URL(string: popup.imageUrlList[0]))
                    .resizable()
                    .aspectRatio(contentMode: .fill) // 프레임을 채움
                    .frame(width: geo.size.width, height: geo.size.height)  // 포스트 사이즈
                    .clipped()                       // 넘치는 영역 제거
            }
            
            // MARK: - 그라데이션
            /// startPoint -> endPoint방향으로 색이 변함
            LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: Color.mainBlack.opacity(0.0), location: 0.0),
                    .init(color: Color.mainBlack.opacity(0.16), location: 0.6),
                    .init(color: Color.mainBlack.opacity(0.56), location: 1.0),
                
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 100) // 이미지 하단 100px 영역만 덮음
            .clipped()          // 그라데이션 100px만 보이고 넘는 부분 차단
            
            // MARK: - 텍스트 오버레이
            VStack(alignment: .leading) {
                Text(popup.name)
                    .font(.scdream(.bold, size: 15))
                    .foregroundStyle(Color.bestPostTitle)
                HStack(spacing: 2) {
                    Image("Address")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color.bestPostAddress)
                        .frame(width: 15, height: 15)
                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.bestPostAddress)
                }
            }
            .padding(11)
        }
        .frame(width: 194, height: 271)
        // .cornerRadius(10)
    }
}

// MARK: - Coming Popup
private struct ComingPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(viewModel.comingPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    ComingPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
                        }
                }
            }
            .padding(.vertical, 15)
            .padding(.trailing, .contentPadding)
        }
        //.background(Color.blue)
    }
}

private struct ComingPopupCell: View {
    let popup: Popup
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.subWhite)
                .frame(width: 283, height: 138)
                // MARK: - Spread 임시
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.mainGray3, lineWidth: 0.05)
                }
                // MARK: - 그림자 작용
                .applyShadow(color: .subWhite2, alpha: 0.2, x: 0, y: 0, blur: 13)
              
            HStack(spacing: 0) {
                // MARK: - 이미지
                KFImage(URL(string: popup.imageUrlList[0]))
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 94.4, height: 118)
                    .cornerRadius(5)
                    .clipped()
                    .padding(10)
                
                // MARK: - 설명문구
                VStack(alignment: .leading, spacing: 5) {
                    Text(dDay(date: popup.startDate))
                        .font(.scdream(.bold, size: 11))
                        .foregroundStyle(Color.mainOrange)
                    Text("\(popup.name)")
                        .font(.scdream(.medium, size: 13))
                        .foregroundStyle(Color.mainBlack)
                    Text("\(popup.roadAddress.shortAddress)")
                        .font(.scdream(.regular, size: 11))
                        .foregroundStyle(Color.mainGray)
                }
                .padding(.bottom, 15)
                
                Spacer()
            }
            .frame(width: 283, height: 138)
        }
        
    }
    
    private func dDay(date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        
        if let diff = calendar.dateComponents([.day], from: today, to: target).day {
            if diff > 0 {
                return "오픈 D-\(diff)"
            } else {
                return "오늘 오픈"
            }
        }
        return ""
    }
}

// MARK: - Current Popup
private struct GridPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var viewModel: HomeViewModel
    private let columns = [
        // flexible: 가로 공간이 남으면 균등하게 나눠 쓰기
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewModel.gridPopups) { popup in
                
                VStack(alignment: .leading) {
                    GridPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
                        }
                        .padding(.bottom, 20)
                }
            }
        }
    }
}

private struct GridPopupCell: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    let popup: Popup
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            ZStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 217, alignment: .center)
                
                GeometryReader { geo in
                    KFImage(URL(string: popup.imageUrlList[0]))
                        .placeholder {
                            Rectangle()
                                .frame(height: 217)
                        }
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: 217, alignment: .center)
                        .clipped() // 넘치는 영역 완전히 제거
                }
                
                .overlay (alignment: .topTrailing) {
                    BookmarkButton(isLiked: homeViewModel.isLiked(popup: popup),
                                   info: .stroke) {
                        
                        // MARK: - 좋아요 토글 및 팝팡뷰 갱신
                        Task {
                            await homeViewModel.toggleLike(popup: popup)
                            await favoriteViewModel.loadFavoritePopups()
                        }
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
                .font(.scdream(.bold, size: 15))
                .foregroundStyle(Color.mainBlack)
                .lineLimit(1) // 한줄만 표시
                .truncationMode(.tail) // 넘치면 ...으로 표시
                .padding(.top, 5)
            
            HStack {
                Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                Text("-")
                Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
            }
            .font(.scdream(.regular, size: 12))
            .foregroundStyle(Color.mainGray)
            .padding(.top, 5)
            .padding(.leading, -1)
        }
    }
}

// MARK: - 찜버튼
struct BookmarkButton: View {
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
                Image(isLiked ? "favorite_fill" : "favorite")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
            case .stroke:
                Image(isLiked ? "favorite_fill" : "favorite")
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 25, height: 25)
                    .foregroundStyle(isLiked ? Color.mainOrange : Color.subWhite)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
        .environmentObject(HomeViewModel(userUuid: "1234"))
}









