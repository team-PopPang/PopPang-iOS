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
            VStack(spacing: 0) {
                
                Text(title)
                    .font(.scdream(.bold, size: 17))
                Text(content)
                    .font(.scdream(.regular, size: 14))
                    .multilineTextAlignment(.center) // 가운데정렬
                    .padding(.top, 20)
                
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
//     @Previewable @State var isPresented: Bool = false
//     CustomPopupView(isPresented: $isPresented, title: "공지사항", content: "팝팡 테스트 공지입니다.\n나중에 사진도 넣으면 어떨까요.")
}


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
                        .cornerRadius(12)
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
