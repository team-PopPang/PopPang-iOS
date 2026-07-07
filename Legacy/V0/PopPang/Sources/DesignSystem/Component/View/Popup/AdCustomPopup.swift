//
//  AdCustomPopup.swift
//  PopPang
//
//  Created by 김동현 on 9/30/25.
//

import SwiftUI

struct AdCustomPopupView: View {
    let imageURL: String?
    let title: String?
    let content: String?
    var onDismiss: () -> Void
    var onDontShowToday: () -> Void
    
    var body: some View {
        ZStack {
            
            // MARK: - 딤 처리
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // MARK: - 팝업 본문
            VStack(spacing: 0) {
                
                if let image = imageURL {
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 300)
                        .cornerRadius(12, corners: [.topLeft, .topRight])
                }
                
                
                VStack {
                    if let title = title {
                        Text(title)
                            .font(.scdream(.bold, size: 17))
                    }
                    
                    if let content = content {
                        Text(content)
                            .font(.scdream(.regular, size: 14))
                            .multilineTextAlignment(.center) // 가운데정렬
                            .padding(.top, 20)
                    }
                    
                    HStack(spacing: 0) {
                        Button {
                            onDismiss()
                        } label: {
                             Text("오늘 하루 보지 않기")
                                .font(.scdream(.bold, size: 14))
                                .foregroundStyle(Color.mainBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                        }
                        
                        Button {
                            onDismiss()
                        } label: {
                             Text("닫기")
                                .font(.scdream(.bold, size: 14))
                                .foregroundStyle(Color.mainOrange)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                        }
                    }
                }
                // .padding(EdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20))
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mainWhite)
            )
            .padding(.horizontal, 30)
            
        }
    }
}


#Preview {
    AdCustomPopupView(imageURL: "img_8",
                      title: nil,
                      content: nil) {
        
    } onDontShowToday: {
        
    }

}
