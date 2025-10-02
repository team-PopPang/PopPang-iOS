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
    // var isVaild: Bool? = nil
    
    var validationState: NicknameValidationState = .none
    
    private var borderColor: Color {
        switch validationState {
        case .none, .checking:
            return .mainGray3
        case .success:
            return .mainGreen
        case .duplicate, .invalidSpace, .tooShort:
            return .mainRed
        }
        
        // 입력 전
        // guard !text.isEmpty else { return .mainGray3 }
        
        // 검증 X
        // guard let isValid = isVaild else { return .mainGray3 }
        
        // 검증 0
        // return isValid ? .mainGreen : .mainRed

    }
    
    private var statusIcon: String? {
        switch validationState {
        case .success: return "Success"               // ✅
        case .duplicate, .invalidSpace, .tooShort: return "Fail" // ❌
        default: return nil
        }
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
                if let icon = statusIcon {
                    Image(icon)
                        .resizable()
                        .frame(width: 15, height: 15)
                        .padding(.horizontal, 16)
                }
            }
        }
        .frame(height: 48)
        .cornerRadius(5)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: 0.8)
        }
        .animation(.easeInOut(duration: 0.15), value: borderColor)
    }
}

#Preview {
    @Previewable @State var nickname = "23"
    
    VStack {
        
        RoundedTextField(placeholder: "닉네임을 입력해주세요",
                         text: $nickname,
                         validationState: .none)
        
        RoundedTextField(placeholder: "닉네임을 입력해주세요",
                         text: $nickname,
                         validationState: .checking)
        
        RoundedTextField(placeholder: "닉네임을 입력해주세요",
                         text: $nickname,
                         validationState: .invalidSpace)
        
        RoundedTextField(placeholder: "닉네임을 입력해주세요",
                         text: $nickname,
                         validationState: .duplicate)
        
        RoundedTextField(placeholder: "닉네임을 입력해주세요",
                         text: $nickname,
                         validationState: .success)
        
    }
    .padding()
}
