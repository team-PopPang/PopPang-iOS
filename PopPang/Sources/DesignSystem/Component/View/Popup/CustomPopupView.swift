//
//  CustomPopupView.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import SwiftUI

struct CustomPopupView: View {
    let title: String
    let content: String
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            
            // MARK: - 딤 처리
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            // MARK: - 팝업 본문
            VStack(alignment: .leading, spacing: 0) {
                
                Text(title)
                    .font(.scdream(.bold, size: 17))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Text(content)
                    .font(.scdream(.regular, size: 14))
                    // .multilineTextAlignment(.center) // 가운데정렬
                    .padding(.top, 20)
                    .padding(.horizontal, 30)
                
                Button {
                    onDismiss()
                } label: {
                    Text("확인")
                        .font(.scdream(.medium, size: 15))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainBlack)
                        .cornerRadius(10)
                        .contentShape(RoundedRectangle(cornerRadius: 10)) // 터치 영역 제한
                }
                .padding(.top, 20)
            }
            .padding(EdgeInsets(top: 30, leading: 20, bottom: 20, trailing: 20))
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.mainWhite)
            )
            .padding(.horizontal, 30)
            
        }
    }
}

#Preview {
    // @Previewable @State var isPresented: Bool = false
    CustomPopupView(title: "베타 업데이트",
                    content: """
                    - 팝팡 테스트 공지입니다.
                    - 나중에 사진도 넣으면 어떨까요.
                    """) {
    }
}



