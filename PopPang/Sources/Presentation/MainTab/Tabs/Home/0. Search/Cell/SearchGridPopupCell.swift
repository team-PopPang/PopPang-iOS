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
