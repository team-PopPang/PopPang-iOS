//
//  CalendarPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 10/17/25.
//

import SwiftUI
import Kingfisher

struct CalendarPopupCell: View {
    let popup: Popup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
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
                    
                    // 주소
                    Text(popup.roadAddress.shortAddress)
                        .font(.scdream(.regular, size: 12))
                        .foregroundStyle(Color.mainBlack)
                    
                    // 제목
                    Text(popup.name)
                        .font(.scdream(.bold, size: 15))
                        .foregroundStyle(Color.mainBlack)
                        .lineLimit(1) // 한줄만 표시
                        .truncationMode(.tail) // 넘치면 ...으로 표시
                        .padding(.top, 5)
                  
                    // 날짜
                    Text("\(popup.startDate, formatter: DateFormatter.popupDateFormat) - \(popup.endDate, formatter: DateFormatter.popupDateFormat)")
                        .ppStyleFontFixedSpacing(.scdream(.regular, size: 12), letterSpacingPt: -1)
                        .foregroundStyle(Color.mainGray)
                        .padding(.top, 5)
                    
                    Spacer()
                    
                    // 조회수
                    HStack(spacing: 5) {
                        
                        Spacer()
                        
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
                }
                .padding(.leading, 18)
                .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
#Preview {
    CalendarPopupCell(popup: .popupMock)
        .frame(height: 133) // 이미지 높이에 맞게 고정
}
