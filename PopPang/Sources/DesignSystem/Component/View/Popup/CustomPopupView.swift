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
    var isCenter: Bool = false
    
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
                    .multilineTextAlignment(isCenter ? .center : .leading)
                    .frame(maxWidth: .infinity, alignment: isCenter ? .center : .leading)
                    // .multilineTextAlignment(isCenter ? .center : .leading) // 가운데정렬
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
    
    let beta_0930 = """
    홈화면 
    • 좌측 드롭다운버튼 글자 17(bold)
    • 우측 드롭다운버튼 글자 12(regular)
    
    팝업 상세화면
    • 글자 24(bold), 15(regular), 12(regular)
    • 좋아요 제거
    • 알림 받기 => 찜하기 변경
    """
    
    // @Previewable @State var isPresented: Bool = false
    CustomPopupView(title: "베타 업데이트",
                    content: beta_0930
    ) {
    }
}



