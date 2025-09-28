//
//  HomeView.swift
//  DevNote
//
//  Created by 김동현 on 9/5/25.
//

import SwiftUI

struct BestPopup: Hashable {
    let imageName: String
    let title: String
    let address: String
}

struct HomeView: View {
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
                HStack(spacing: 0) {
                    SearchTextField(placeholder: "궁금한 장소를 검색해보세요",
                                    text: $searchText)
                    .disabled(true)
                    .overlay {
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                coordinator.push(.search)
                            }
                    }
                    
                    AlertButton {
                        print("알림 버튼 클릭됨")
                        coordinator.presentOverlay(overlay: .notice(title: "공지사항",
                                                                    content: "키워드 화면 구현 예정입니다."))
                    }
                    .padding(.leading, .contentPadding)
                }
                .padding(.top, .contentPadding)
                .padding(.horizontal, .contentPadding)
                .padding(.bottom, 10)
                
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - Best Popup
                        BestPopupScrollView(viewModel: homeViewModel)
                        
                        // MARK: - Coming Popup
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("COMING SOON")
                                    .font(.scdream(.medium, size: 11))
                                    .foregroundStyle(Color.mainOrange)
                                
                                Text("곧 생기는 팝업")
                                    .font(.scdream(.bold, size: 15))
                                
                            }
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Image("navigationBtn")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 16, height: 16)
                            }
                            .padding(.trailing, .contentPadding)
                        }
                        .padding(.top, 25)
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
                                         maxWidth: 100,
                                         selection: $selectRegion,
                                         overlay: false
                            )
                            
                            Spacer()
                            
                            DropDownView(options: [
                                            "가까운순",
                                            "추천순",
                                         ],
                                         anchor: .bottom,
                                         maxWidth: 110,
                                         cornerRadius: 17,
                                         stroke: .mainGray5,
                                         imgSize: 10,
                                         imgColor: .mainGray2,
                                         selection: $selectSort,
                                         overlay: true
                            )
                        }
                        .zIndex(1)
                        .padding(.top, 20)
                        .padding(.trailing, .contentPadding)
                        
                        // MARK: - GridView
                        GridPopupScroppView(viewModel: homeViewModel)
                        .padding(.top, 15)
                        .padding(.trailing, .contentPadding)
                        
                        // Spacer()
                    }
                }
                .padding(.leading, .contentPadding)
            }
        }
        .onAppear {
            if !hasSeenPopup {
                coordinator.presentOverlay(overlay: .ad(image: "img_8"))
                hasSeenPopup = true
            }
        }
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
            
            // MARK: - 이미지
            Image("\(popup.imageURL)")
                .resizable()
                .aspectRatio(contentMode: .fill) // 프레임을 채움
                .frame(width: 194, height: 271)  // 포스트 사이즈
                .clipped()                       // 넘치는 영역 제거
            
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
            
            // 기본 버전
            // .frame(width: 194, height: 271) // 이미지와 동일 크기
            // .clipped()
           
            
            // MARK: - 텍스트 오버레이
            VStack(alignment: .leading) {
                Text(popup.name)
                    .font(.scdream(.bold, size: 14))
                    .foregroundStyle(Color.bestPostTitle)
                HStack(spacing: 2) {
                    Image("Address")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .foregroundStyle(Color.bestPostAddress)
                        .frame(width: 15, height: 15)
                    Text(popup.address)
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.bestPostAddress)
                }
            }
            .padding(11)
        }
    }
}

// MARK: - Coming Popuo
private struct ComingPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var viewModel: HomeViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.comingPopups, id: \.self) { popup in
                    
                    // MARK: - Cell
                    ComingPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
                        }
                    
                }
            }
            .padding(.vertical, 10)
            .padding(.trailing, .contentPadding)
        }
    }
}

private struct ComingPopupCell: View {
    let popup: Popup
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.subWhite)
                .frame(width: 289, height: 114)
                // MARK: - Spread 임시
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.subWhite2, lineWidth: 0.05)
                }
                // MARK: - 그림자 작용
                .applyShadow(color: .subWhite2, alpha: 0.2, x: 0, y: 0, blur: 13)
              
               
            
            HStack(spacing: 0) {
                // MARK: - 이미지
                Image(popup.imageURL)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 83, height: 104)
                    .clipped()
                    .padding(5)
                
                // MARK: - 설명문구
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("10.05 오픈")
                            .font(.scdream(.medium, size: 11))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 7)
                            .background(Color.mainOrange)
                            .foregroundStyle(Color.subWhite)
                            .clipShape(Capsule())
                        
                        Spacer()
                        
                        LikeButton {
                            
                        }
            
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 15)
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Text("\(popup.name)")
                            .font(.scdream(.medium, size: 13))
                        Text("\(popup.address)")
                            .font(.scdream(.regular, size: 11))
                    }
                    .padding(.bottom, 15)
                }
                .padding(.leading, 5)
            }
            .frame(width: 289, height: 114)
        }
    }
}

private struct LikeButton: View {
    @State private var isLiked: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button {
            isLiked.toggle()
            action()
        } label: {
            Image(isLiked ? "like_fill" : "like")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
        }
    }
}

// MARK: - Current Popup
private struct GridPopupScroppView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var viewModel: HomeViewModel
    private let columns = [
        // flexible: 가로 공간이 남으면 균등하게 나눠 쓰기
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 20) {
            ForEach(viewModel.gridPopups) { popup in
                
                VStack(alignment: .leading) {
                    GridPopupCell(popup: popup)
                        .onTapGesture {
                            coordinator.push(.popupDetail(popup))
                        }
                }
            }
        }
    }
}

private struct GridPopupCell: View {
    let popup: Popup
    var body: some View {
        Image(popup.imageURL)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 206)
            .clipped()
        
        Text(popup.name)
            .font(.scdream(.bold, size: 15))
        
        
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Image("Address")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(Color.mainGray)
                    .frame(width: 15, height: 15)
                
                Text(popup.address)
                    .font(.scdream(.medium, size: 11))
                    .foregroundStyle(Color.mainGray)
            }
            
            HStack {
                Text(popup.startDate, formatter: DateFormatter.popupDateFormat)
                Text("-")
                Text(popup.endDate, formatter: DateFormatter.popupDateFormat)
            }
            .font(.scdream(.medium, size: 11))
            .foregroundStyle(Color.mainGray)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
}

extension View {
    func applyShadow(
        color: Color = .black,
        alpha: Double = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 20,
        blur: CGFloat = 35
    ) -> some View {
        self.shadow(
            color: color.opacity(alpha),
            radius: blur / 2,
            x: x,
            y: y
        )
    }
}
