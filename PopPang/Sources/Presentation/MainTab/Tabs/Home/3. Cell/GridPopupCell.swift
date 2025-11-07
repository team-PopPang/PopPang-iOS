//
//  2. GridPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI
import Kingfisher

struct GridPopupCell: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    @EnvironmentObject private var calendarViewModel: CalendarViewModel
    let popup: Popup

    // 셀 너비를 미리 계산해서 전달받거나 상수로 지정
    let cellWidth: CGFloat = (UIScreen.main.bounds.width - 15 * 3) / 2  // 2열 기준

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                KFImage(URL(string: popup.imageUrlList[0]))
                    .placeholder {
                        Rectangle()
                            .fill(Color.subWhite)
                            .frame(width: cellWidth, height: 217)
                    }
                    .resizable()
                    .scaledToFill()
                    .frame(width: cellWidth, height: 217)
                    .clipped()

                BookmarkButton(
                    isLiked: homeViewModel.isLiked(popup: popup),
                    info: .stroke
                ) {
                    Task {
                        await homeViewModel.toggleLike(popup: popup)
                        await favoriteViewModel.getFavoritePopups()
                        await calendarViewModel.getAllPopupData()
                    }
                }
                .padding(10)
                .applyShadow(color: .mainBlack, alpha: 0.25, x: 0, y: 1, blur: 3)
            }
            .frame(width: cellWidth, height: 217)

            Text(popup.roadAddress.shortAddress)
                .font(.scdream(.regular, size: 12))
                .foregroundStyle(Color.mainBlack)
                .padding(.top, 10)

            Text(popup.name)
                .font(.scdream(.bold, size: 15))
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
