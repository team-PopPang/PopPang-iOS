//
//  SearchGridPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI
import Kingfisher

struct SearchGridPopupCell: View {
    @EnvironmentObject private var searchViewModel: SearchViewModel
    @EnvironmentObject private var favoriteViewModel: FavoriteViewModel
    let popup: Popup
    
    // 셀 너비를 미리 계산해서 전달받거나 상수로 지정
    let cellWidth: CGFloat = (UIScreen.main.bounds.width - 15 * 3) / 2  // 2열 기준
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            ZStack {
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
            
            Text("\(popup.startDate, formatter: DateFormatter.popupDateFormat) - \(popup.endDate, formatter: DateFormatter.popupDateFormat)")
                .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
                .foregroundStyle(Color.mainGray)
                .padding(.top, 5)
        }
    }
}
