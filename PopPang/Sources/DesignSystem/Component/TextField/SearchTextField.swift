//
//  SearchTextField.swift
//  PopPang
//
//  Created by 김동현 on 9/25/25.
//

import SwiftUI

struct SearchTextField: View {
    
    var placeholder: String
    @Binding var text: String
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            HStack {
                // 입력
                TextField("", text: $text)
                    .font(.scdream(.medium, size: 11))
                    .frame(height: 45)
                    .keyboardType(.default)
                    .padding(.horizontal, 16)
                    .tint(.mainBlack)
                    .background(Color.mainGray4)
                    .cornerRadius(5)
                    .contentShape(Rectangle())
                    .overlay(
                        HStack {
                            Spacer()
                            Image("Search")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color.mainGray)
                                .frame(width: 17, height: 17)
                                .padding(.trailing, 16)
                                .allowsHitTesting(false) 
                        }
                    )
            }
            
            // 플레이스홀더
            if text.isEmpty {
                Text(placeholder)
                    .ppStyleFont(.scdream(.regular, size: 11))
                    .foregroundStyle(Color.mainGray)
                    .padding(.horizontal, 15)
                    .opacity(text.isEmpty ? 1 : 0)
            }
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    VStack {
        SearchTextField(placeholder: "궁금한 장소를 검색해보세요", text: $text)
    }
    .padding(.contentPadding)
}



//                    .overlay {
//                        HStack {
//                            // 돋보기 UI
//                            Spacer()
//                            Image("Search")
//                                .resizable()
//                                .aspectRatio(contentMode: .fit)
//                                .frame(width: 20, height: 20)
//                                .padding(.trailing, 16)
//                        }
//                    }
