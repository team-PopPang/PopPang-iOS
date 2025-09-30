//
//  PopupDetailView.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import SwiftUI

struct PopupDetailView: View {
    @EnvironmentObject private var homeViewModel: HomeViewModel
    let popup: Popup
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading) {
                    /*
                     Image(popup.imageURL)
                     .resizable()
                     .aspectRatio(contentMode: .fill)
                     .frame(height: 450)
                     .clipped()
                     */
                    GeometryReader { geo in
                        let offset = geo.frame(in: .global).minY
                        Image(popup.imageURL)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width,
                                   height: 450 + (offset > 0 ? offset : 0)) // 세로만 늘어남
                            .clipped()
                            .offset(y: (offset > 0 ? -offset : 0)) // 위로 당길 때 자연스럽게 보정
                    }
                    .frame(height: 450) // 기본 높이
                    
                    VStack(alignment: .leading) {
                        
                        // MARK: - Title
                        Text(popup.name)
                            .font(.scdream(.bold, size: 24))
                            .foregroundStyle(Color.mainBlack)
                        
                        // MARK: - Info
                        InfoView(popup: popup)
                            .padding(.top, 20)
                        
                        Divider()
                            .background(Color.mainBlack)
                            .padding(.vertical, 15)
                        
                        // MARK: - Body
                        Text(popup.captionSummary)
//                            .font(.scdream(.regular, size: 12))
                            .ppStyleFont(.scdream(.regular, size: 12),
                                       lineHeight: 1.4,
                                       letterSpacing: 0.02)
                        
                    }
                    .padding(.top, 20)
                    .padding(.horizontal, .contentPadding)
                    
                    Spacer()
                        .frame(height: 500)
                }
            }
            .ignoresSafeArea()
            
            HStack {
                MainOrangeButton(buttonTitle: "찜하기") {
                    
                }
                
                IconButton(image: "share", imageSize: 25) {
                    
                }
            }
            .padding(.top, 10)
            .padding(.horizontal, .contentPadding)
            .background(Color.mainGray4)
            
        }
        
    }
}

private struct InfoView: View {
    let popup: Popup
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 20) {
                Text("운영 장소")
                Text("\(popup.address)")
            }
            
            HStack(spacing: 20) {
                Text("운영 날짜")
                HStack(spacing: 10) {
                    Text(popup.openTime, formatter: DateFormatter.popupDateFormat)
                    Text("-")
                    Text(popup.closeTime, formatter: DateFormatter.popupDateFormat)
                }
            }
            
            HStack(spacing: 20) {
                Text("운영 시간")
                HStack(spacing: 10) {
                    Text(popup.startDate, formatter: DateFormatter.popupTimeFormat)
                    Text("-")
                    Text(popup.endDate, formatter: DateFormatter.popupTimeFormat)
                }
            }
        }
        .font(.scdream(.regular, size: 15))
    }
}

#Preview {
    PopupDetailView(popup: Popup.popupMock)
}
