//
//  MapListPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 10/23/25.
//

import SwiftUI
import Kingfisher

struct MapListPopupCell: View {
    let popup: Popup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                KFImage(URL(string: popup.imageUrlList[0]))
                    .placeholder {
                        Rectangle()
                            .fill(Color.mainGray3)
                            .frame(width: 106, height: 133)
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 106, height: 133, alignment: .center)
                    .clipped()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                    
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
                    
                    Spacer()
                    
                    // 조회수
                    HStack(spacing: 5) {
                        
                        Spacer()
                        
                        Image("viewCount")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                        
                        Text("\(popup.viewCount)")
                            .ppStyleFont(.scdream(.regular, size: 9))
                        
                        Image("favoriteCount")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                        
                        Text("\(popup.favoriteCount)")
                            .ppStyleFont(.scdream(.regular, size: 9))
                        
                    }
                }
                .padding(.leading, 18)
                .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }
}
