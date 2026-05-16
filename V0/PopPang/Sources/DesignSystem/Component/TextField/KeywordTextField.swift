//
//  KeywordTextField.swift
//  PopPang
//
//  Created by 김동현 on 10/27/25.
//

import SwiftUI

struct KeywordTextField: View {
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                TextField("", text: $text)
                    .font(.scdream(.medium, size: 12))
                    .frame(height: 48)
                    .keyboardType(.default)
                    .padding(.horizontal, 12)
                    .tint(.mainBlack)
                    .background(Color.subWhite)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 1)
                            .foregroundStyle(Color.mainGray7)
                            .padding(.horizontal, 5) // 좌우 패딩 조절 가능
                    }
            }
            
            // 플레이스홀더
            if text.isEmpty {
                Text(placeholder)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray2)
                    .opacity(text.isEmpty ? 1 : 0)
                    .padding(.horizontal, 12)
            }
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    VStack {
        KeywordTextField(placeholder: "궁금한 팝업을 검색해보세요",
                           text: $text)
            .padding(.contentPadding)
    }
}
