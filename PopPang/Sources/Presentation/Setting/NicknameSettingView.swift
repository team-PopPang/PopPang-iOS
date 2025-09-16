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
    @EnvironmentObject var coordinator: Coordinator<OnboardingRoute, SheetRoute>
    
    var body: some View {
        VStack(alignment: .leading) {
            StepIndicatorView(currentStep: step)
                .padding(.top, 10)
            
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
                }
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
                // coordinator.push(.categorySetting)
            }
            // 키보드 올라오면 공백과 함께 버튼 올라감
            .padding(.bottom, 20)
            .frame(maxHeight: .infinity, alignment: .bottom)
            
        }
        .padding(.horizontal, 16)
        .task {
            await Task.yield()
            isFocused = true
            
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if !text.isEmpty {
                isValid = true
            }
        }
    }
}

#Preview {
    NicknameSettingView()
}

struct StepIndicatorView: View {
    var currentStep: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...3, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.mainOrange : Color.gray.opacity(0.3))
                    .frame(height: 3)
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.5), value: currentStep)
    }
}



//
//  OnboardingProgressBarView.swift
//  WSSiOS
//
//  Created by SwiftUI Conversion
//

import SwiftUI

struct OnboardingProgressBarView: View {
    let progress: CGFloat // 0.0 ~ 1.0
    let animationDuration: Double = 0.2
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background (Gray)
                Rectangle()
                    .fill(Color.wssGray70)
                    .frame(height: 4)
                
                // Progress (Purple)
                Rectangle()
                    .fill(Color.wssPrimary100)
                    .frame(width: geometry.size.width * progress, height: 4)
                    .animation(.easeInOut(duration: animationDuration), value: progress)
            }
        }
        .frame(height: 4)
    }
}


// MARK: - Color Extensions
extension Color {
    static let wssGray70 = Color(red: 0.8, green: 0.8, blue: 0.8) // 임시 색상
    static let wssPrimary100 = Color(red: 0.415, green: 0.365, blue: 0.992) // #6A5DFD
}

#Preview {
    OnboardingProgressBarView(progress: 0.33)
    OnboardingProgressBarView(progress: 0.66)
    OnboardingProgressBarView(progress: 1.0)
}
