//
//  BestPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI
import Kingfisher

struct BestPopupCell: View {
    let popup: Popup
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            
            // MARK: - 이미지
            KFImage(URL(string: popup.imageUrlList[0]))
                .downSampled(.bestPopupCell)
                // .resizable()
                .scaledToFill()
                .frame(width: 194, height: 271)
                .clipped()                       // 넘치는 영역 제거
            
            // MARK: - 그라데이션
            /// startPoint -> endPoint방향으로 색이 변함
            LinearGradient(
                gradient: Gradient(stops: [
//                    .init(color: Color.mainBlack.opacity(0.0), location: 0.0),
//                    .init(color: Color.mainBlack.opacity(0.16), location: 0.6),
//                    .init(color: Color.mainBlack.opacity(0.56), location: 1.0),
                    .init(color: Color.mainBlack.opacity(0.0), location: 0.00),   // 0%
                    .init(color: Color.mainBlack.opacity(0.50), location: 0.52),  // 52%
                    .init(color: Color.mainBlack.opacity(1.00), location: 0.83),  // 83%
                    
                    
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
                    .lineLimit(1)
                    .truncationMode(.tail)
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
        .contentShape(Rectangle())
    }
}
