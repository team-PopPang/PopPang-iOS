//
//  NicknameSettingView.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

struct NicknameSettingView: View {
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    @State private var isValid: Bool? = nil
    @State private var step = 1
    @EnvironmentObject var coordinator: Coordinator<RegisterRoute, SheetRoute>
    var onNext: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("닉네임을\n설정해주세요.")
                        .font(.scdream(.bold, size: 17))
                    Text("닉네임은 나중에 변경할 수 있습니다.")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGray)
                }
                Spacer()
            }
            .padding(.top, 50)
            
            HStack(spacing: 10) {
                RoundedTextField(placeholder: "닉네임을 입력해 주세요",
                                 text: $text,
                                 isVaild: isValid)
                .focused($isFocused)
                
                Button {
                    step += 1
                } label: {
                    Text("중복확인")
                        .font(.scdream(.medium, size: 12))
                        .frame(width: 100)
                        .frame(height: 48)
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainOrange)
                        .cornerRadius(5)
                }.buttonStyle(PressableButtonStyle())
            }
            .padding(.top, 20)
            
            if !text.isEmpty, let isValid {
                Text(isValid ? "사용 가능한 닉네임입니다." : "이미 사용 중인 닉네임입니다.")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(isValid ? Color.textFieldGr : Color.textFieldRe)
                    .padding(.top, 5)
            }
            
            Spacer()
            
            NextButton(buttonTitle: "다음") {
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
            .frame(maxHeight: .infinity, alignment: .bottom)
            
        }
        .padding(.horizontal, 24)
        .task {
            // await Task.yield()
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3초
            isFocused = true
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !text.isEmpty {
                isValid = true
            }
        }
    }
}

#Preview {
    NicknameSettingView {
        
    }
}
