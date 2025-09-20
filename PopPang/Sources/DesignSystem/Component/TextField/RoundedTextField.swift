//
//  RoundedTextField.swift
//  PopPang
//
//  Created by 김동현 on 9/15/25.
//

import SwiftUI

struct RoundedTextField: View {
    
    var placeholder: String
    @Binding var text: String
    
    /// 뷰모델에서 던져주는 유효성 결과
    /// nil이면 검증 x, true면 초록, false면 빨강
    var isVaild: Bool? = nil
    
    private var borderColor: Color {
        
        // 입력 전
        guard !text.isEmpty else { return .mainGray3 }
        
        // 검증 X
        guard let isValid = isVaild else { return .mainGray3 }
        
        // 검증 0
        return isValid ? .mainGreen : .mainRed
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            // 플레이스홀더
            if text.isEmpty {
                Text(placeholder)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray2)
                    .padding(.horizontal, 16)
                    .opacity(text.isEmpty ? 1 : 0)
            }
            
            HStack {
                // 입력
                TextField("", text: $text)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainBlack)
                    .keyboardType(.default)
                    .padding(.horizontal, 16)
                    .tint(.mainBlack)
                
                // 성공유무 이미지
                if !text.isEmpty, let isVaild {
                    Image(isVaild ? "Success" : "Fail")
                        .resizable()
                        .frame(width: 15, height: 15)
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(height: 48)
        // .background(Color.textFieldBg)
        .cornerRadius(5)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 0.8)
        }
        .animation(.easeInOut(duration: 0.15), value: borderColor)
    }
}

#Preview {
    @Previewable @State var nickname = ""
    @Previewable @State var pages = ""
    
    VStack {
        RoundedTextField(placeholder: "닉네임을 입력해주세요",
                         text: $nickname)
        
        RoundedTextField(placeholder: "닉네임을 입력해주세요",
                         text: $nickname,
                         isVaild: false)
        
        RoundedTextField(placeholder: "닉네임을 입력해주세요",
                         text: $nickname,
                         isVaild: true)
    }
    .padding()
}
