//
//  KeywordSettingView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct KeywordSettingView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    // 중복 검사
    @State private var keywords: [String] = []
    @State private var keywordSet: Set<String> = []
    @State private var showDuplicateWarning = false
    
    var onNext: () -> Void
    var body: some View {

        VStack(alignment: .leading) {
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("키워드를\n입력해주세요.")
                        .font(.scdream(.bold, size: 17))
                    Text("등록된 키워드에 맞춰 알림을 받아볼 수 있어요.")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGray)
                }
                Spacer()
            }
            .padding(.top, 50)
            
            HStack(spacing: 10) {
                RoundedTextField(placeholder: "알림 받고 싶은 키워드를 입력해주세요",
                                 text: $text)
                .focused($isFocused)
                
                Button {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    
                    if keywordSet.contains(trimmed) {
                        showDuplicateWarning = true
                        return
                    }
                    keywords.append(trimmed)
                    keywordSet.insert(trimmed)
                    showDuplicateWarning = false
                    text = ""
                } label: {
                    Text("등록")
                        .font(.scdream(.medium, size: 12))
                        .frame(width: 70)
                        .frame(height: 48)
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainOrange)
                        .cornerRadius(5)
                }.buttonStyle(PressableButtonStyle())
            }
            .padding(.top, 20)
            
            ForEach(Array(keywords.enumerated()), id: \.1) { index, keyword in
                HStack {
                     Text(keyword)
                    Spacer()
                    Button {
                        let removed = keywords.remove(at: index)
                        keywordSet.remove(removed)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.mainGray)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
            }
            .padding(.top, 20)
            
            Spacer()
            
            NextButton(buttonTitle: "다음") {
                rootViewModel.updateKeywords(keywords)
                // print("현재 진행중: \(rootViewModel.user!)")
                DispatchQueue.main.async {
                    onNext()
                }
            }
            // 키보드 올라오면 공백과 함께 버튼 올라감
            .padding(.bottom, 20)
        }
        .padding(.horizontal, .contentPadding)
    }
}

#Preview {
    KeywordSettingView {}
        .environmentObject(RootViewModel())
    
}
