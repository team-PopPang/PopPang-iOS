//
//  AlertPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI
import Kingfisher

struct AlertPopupCell: View {
    let popup: Popup
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                    // MARK: - 이미지
                    KFImage(URL(string: popup.imageUrlList[0]))
                        .resizable()
                        .aspectRatio(contentMode: .fill) // 프레임을 채움
                        .frame(width: 106, height: 133)  // 포스트 사이즈
                        .clipped()                       // 넘치는 영역 제거
                
                VStack(alignment: .leading, spacing: 0) {
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
                .padding(.top, 10)
                
                Spacer()
            }
        }
        // .background(.blue)
        .padding(.vertical, 15)
    }
}
