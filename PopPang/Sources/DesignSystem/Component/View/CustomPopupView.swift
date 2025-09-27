//
//  CustomPopupView.swift
//  PopPang
//
//  Created by 김동현 on 9/28/25.
//

import SwiftUI

struct CustomPopupView: View {
    @Binding var isPresented: Bool
    let title: String
    let content: String
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Text(title)
                    .font(.scdream(.bold, size: 17))
                Text(content)
                    .font(.scdream(.regular, size: 14))
                    .multilineTextAlignment(.center) // 가운데정렬
                    .padding(.top, 20)
                
                Button {
                    isPresented.toggle()
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
    @Previewable @State var isPresented: Bool = false
    CustomPopupView(isPresented: $isPresented, title: "공지사항", content: "팝팡 테스트 공지입니다.\n나중에 사진도 넣으면 어떨까요.")
}
