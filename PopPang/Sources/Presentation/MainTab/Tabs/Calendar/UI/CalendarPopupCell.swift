//
//  CalendarPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 10/17/25.
//

import SwiftUI
import Kingfisher
import AutoEquatable

@AutoEquatable
struct CalendarPopupCell: View {
    
    @AutoRequiredChild(\Popup.popupUuid)
    let popup: Popup
    let isLiked: Bool
    let onToggleLike: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                KFImage(URL(string: popup.imageUrlList[0]))
                    .placeholder {
                        Rectangle()
                            .fill(Color.mainGray3)
                            .frame(width: 106, height: 133)
                    }
                    .downSampled(.calendarPopupCell)
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
                        .font(.scdream(.medium, size: 14))
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
                    
                    // 조회수 & 좋아요
                    HStack(spacing: 5) {
                        
                        Spacer()
                        
                        Image("viewCount")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 12, height: 12)
                        
                        Text("\(popup.viewCount)")
                            .ppStyleFont(.scdream(.regular, size: 9))
                        
                        
                        Button {
                            onToggleLike()
                        } label: {
                            HStack(spacing: 5) {
                                Image("favoriteCount")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)
                                
                                Text("\(popup.favoriteCount)")
                                    .ppStyleFont(.scdream(.regular, size: 9))
                            }
                        }
                        .foregroundStyle(isLiked ? Color.mainOrange : Color.mainGray)
                        //.foregroundStyle(calendarViewModel.isLiked(popup: popup) ? Color.mainOrange : Color.mainGray)
                    }
                
                }
                .padding(.leading, 18)
                .padding(.vertical, 10)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
        .debugBodyRandomBackground()
    }
}

//#Preview {
//    CalendarPopupCell(popup: .popupMock)
//        .frame(height: 133) // 이미지 높이에 맞게 고정
//}
