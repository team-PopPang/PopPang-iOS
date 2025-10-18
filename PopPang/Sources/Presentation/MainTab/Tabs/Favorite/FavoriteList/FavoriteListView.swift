//
//  ListView.swift
//  PopPang
//
//  Created by 김동현 on 10/18/25.
//

import SwiftUI
import Kingfisher

struct FavoriteListView: View {
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    var body: some View {
        VStack(spacing: 0) {
            ListGridPopupScrollView(favoriteViewModel: favoriteViewModel)
                .padding(.top, 24)
        }
        .padding(.horizontal, .contentPadding)
    }
}

private struct ListGridPopupScrollView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @ObservedObject var favoriteViewModel: FavoriteViewModel
    private let columns = [
        // flexible: 가로 공간이 남으면 균등하게 나눠 쓰기
        GridItem(.flexible(), spacing: 15),
        GridItem(.flexible(), spacing: 15)
    ]
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(favoriteViewModel.favoritePopups) { popup in
                    VStack(alignment: .leading) {
                        ListPopupCell(popup: popup)
                            .onTapGesture {
                                coordinator.push(.popupDetail(popup))
                            }
                            .padding(.bottom, 20)
                    }
                }
            }
        }
    }
}

private struct ListPopupCell: View {
    @EnvironmentObject private var bookmarkViewModel: FavoriteViewModel
    @EnvironmentObject private var homeViewModel: HomeViewModel
    let popup: Popup
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 0) {
            
            ZStack {
                Rectangle()
                    .fill(Color.blue)
                    .frame(height: 217, alignment: .center)
                
                GeometryReader { geo in
                    KFImage(URL(string: popup.imageURL))
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
                    BookmarkButton(isLiked: bookmarkViewModel.isLiked(popup: popup),
                                   info: .stroke) {
                        
                        // MARK: - 좋아요 해제 후 홈뷰 갱시
                        Task {
                            await bookmarkViewModel.toggleLike(popup: popup)
                            await homeViewModel.getFavoriteList()
                        }
                    }
                   .padding(10)
                   .applyShadow(color: .mainBlack, alpha: 0.25, x: 0, y: 1, blur: 3)
                }
            }
            .frame(height: 217)
            
            Text(popup.roadAddress?.shortAddress ?? popup.address.shortAddress)
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

#Preview {
    FavoriteListView()
}
