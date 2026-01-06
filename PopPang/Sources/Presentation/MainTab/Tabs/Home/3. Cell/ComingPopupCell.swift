//
//  1. ComingPopupCell.swift
//  PopPang
//
//  Created by 김동현 on 11/6/25.
//

import SwiftUI
import Kingfisher

struct ComingPopupCell: View {
    let popup: Popup
    var body: some View {
        ZStack {
            
            RoundedRectangle(cornerRadius: 5)
                .fill(Color.subWhite)
                .frame(width: 283, height: 138)
                // MARK: - Spread 임시
                .overlay {
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.mainGray3, lineWidth: 0.05)
                }
                // MARK: - 그림자 적용
                .applyShadow(color: .subWhite2, alpha: 0.2, x: 0, y: 0, blur: 13)
            
            HStack(spacing: 0) {
                // MARK: - 이미지
                KFImage(URL(string: popup.imageUrlList[0]))
                    .downSampled(.comingPopupCell)
                    // .resizable()
                    .scaledToFill()
                    .frame(width: 94.4, height: 118)
                    .cornerRadius(5)
                    .clipped()
                    .padding(10)
                
                // MARK: - 설명문구
                VStack(alignment: .leading, spacing: 5) {
                    Text(dDay(date: popup.startDate))
                        .font(.scdream(.bold, size: 11))
                        .foregroundStyle(Color.mainOrange)
                    Text("\(popup.name)")
                        .font(.scdream(.medium, size: 13))
                        .foregroundStyle(Color.mainBlack)
                    
                    Spacer()
                    
                    Text("\(popup.roadAddress.shortAddress)")
                        .font(.scdream(.regular, size: 11))
                        .foregroundStyle(Color.mainGray)
                }
                .padding(.vertical, 15)
                
                Spacer()
            }
            .frame(width: 283, height: 138)
        }
        .contentShape(Rectangle())
    }
    
    private func dDay(date: Date) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let target = calendar.startOfDay(for: date)
        
        if let diff = calendar.dateComponents([.day], from: today, to: target).day {
            if diff > 0 {
                return "오픈 D-\(diff)"
            } else {
                return "오늘 오픈"
            }
        }
        return ""
    }
}

