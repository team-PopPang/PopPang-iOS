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
                KeywordTextField(placeholder: "ex) 화장품, 애니메이션",
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
            
            VStack(spacing: 0) {
                ForEach(Array(keywords.enumerated()), id: \.1) { index, keyword in
                    HStack {
                        Text(keyword)
                        Spacer()
                        Button {
                            let removed = keywords.remove(at: index)
                            keywordSet.remove(removed)
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
            .padding(.top, 20)
            
            Spacer()
            
            MainOrangeButton(buttonTitle: "다음") {
                rootViewModel.send(action: .setalertList(keywords))
//                DispatchQueue.main.async {
//                    onNext()
//                }
                UIApplication.shared.endEditing(true)
                Task {
                    try? await Task.sleep(nanoseconds: 700_000_000) // 0.7초
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onNext()
                    }
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
