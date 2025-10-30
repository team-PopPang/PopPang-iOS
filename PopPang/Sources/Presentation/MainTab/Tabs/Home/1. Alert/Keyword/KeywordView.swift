//
//  KeywordView.swift
//  PopPang
//
//  Created by 김동현 on 10/13/25.
//

import SwiftUI

struct KeywordView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    @ObservedObject var keywordViewModel: KeywordViewModel
    @State private var text: String = ""
    @State private var categories: [String] = UserDefaultsManager.load()
    
    var body: some View {
        VStack {
            
            HStack(spacing: .contentPadding) {
                KeywordTextField(placeholder: "알림 받고 싶은 키워드를 입력해주세요",
                                 text: $text)
                Button {
                    keywordViewModel.addKeyword(text)
                    text = ""
                } label: {
                    Image("plus")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                }
            }
            
            VStack(spacing: 0) {
                ForEach(Array(keywordViewModel.keywordList.enumerated()), id: \.1.id ) { index, keyword in
                    HStack {
                        Text(keyword.keyword)
                            .ppStyleFont(.scdream(.medium, size: 12))
                        Spacer()
                        Button {
                            keywordViewModel.removeKeyword(at: index, keyword: keyword.keyword)
                        } label: {
                            Image(systemName: "xmark")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 10, height: 10)
                                .foregroundStyle(Color.mainGray)
                            
                        }
                    }
                    .padding(.top, 17)
                    .padding(.horizontal, 5)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundStyle(Color.mainGray7)
                        .padding(.top, 5)
                        .padding(.horizontal, 5) // 좌우 패딩 조절 가능
                }
            }
            .padding(.top, 10)
            
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(rootViewModel.user?.nickname ?? "홍길동")
                        .foregroundStyle(Color.mainOrange)
                        .font(.scdream(.bold, size: 12))
                    Text("님의 최근 본 검색어예요")
                        .font(.scdream(.regular, size: 12))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                
                // 선택 버튼들
                SearchFlowLayout {
                    ForEach(categories, id: \.self) { category in
                        SearchFlowButton(title: category) {
                            self.text = category
                        } onRemove: {
                            if let index = categories.firstIndex(of: category) {
                                categories.remove(at: index)
                                UserDefaultsManager.remove(category)
                            }
                        }
                    }
                    .padding(4)
                }
                .padding(.top, 15)
            }
            .padding(.top, 30)
            
            
            Spacer()
        }
        .padding(.top, 24)
        .padding(.horizontal, .contentPadding)
    }
}

#Preview {
    KeywordView(keywordViewModel: KeywordViewModel(userUuid: "1234"))
}

