//
//  MapSearchTextField.swift
//  PopPang
//
//  Created by 김동현 on 10/23/25.
//

import SwiftUI

struct MapSearchTextField: View {
    var placeholder: String
    var background: Color = .subWhite
    @Binding var text: String
    @FocusState private var isFocused: Bool
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack {
                TextField("", text: $text)
                    .font(.scdream(.medium, size: 12))
                    .frame(height: 45)
                    .keyboardType(.default)
                    .padding(.horizontal, 10)
                    .tint(.mainBlack)
                    .background(background)
                    .cornerRadius(3)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isFocused = true
                        onTap?()
                    }
                    .overlay {
                        HStack {
                            Spacer()
                            Image("Search")
                                .renderingMode(.template)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .foregroundStyle(Color.mainGray2)
                                .frame(width: 17, height: 17)
                                .padding(.trailing, 24)
                        }
                    }
            }
            
            // 플레이스홀더
            if text.isEmpty {
                Text(placeholder)
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray2)
                    .opacity(text.isEmpty ? 1 : 0)
                    .padding(.horizontal, 10)
            }
        }
    }
}

#Preview {
    @Previewable @State var text = ""
    VStack {
        MapSearchTextField(placeholder: "궁금한 팝업을 검색해보세요",
                           text: $text)
            .padding(.contentPadding)
    }
}
