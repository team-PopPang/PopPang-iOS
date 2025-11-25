//
//  NicknameSettingView.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

struct NicknameSettingView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    // @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    // MARK: - nil이면 미검증, true이면 성고으 false면 실패
    // @State private var isValid: Bool? = nil
    @EnvironmentObject var coordinator: Coordinator<RegisterRoute, SheetRoute, OverlayRoute, FullScreenRoute>
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
                                 text: $rootViewModel.nickname,
                                 validationState: rootViewModel.validationState)
                .focused($isFocused)
                
                // MARK: - 실시간 바인딩 검증
                Button {
                    rootViewModel.send(action: .checkNickname)
                } label: {
                    Text("중복확인")
                        .font(.scdream(.medium, size: 12))
                        .frame(width: 100)
                        .frame(height: 48)
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainOrange)
                        .cornerRadius(5)
                }
                .buttonStyle(PressableButtonStyle())                
            }
            .padding(.top, 20)
            
            if !rootViewModel.nickname.isEmpty {
                switch rootViewModel.validationState {
                case .success:
                    Text("사용 가능한 닉네임입니다.")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainGreen)
                        .padding(.top, 5)
                case .duplicate:
                    Text("이미 사용 중인 닉네임입니다.")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainRed)
                        .padding(.top, 5)
                case .invalidSpace:
                    Text("공백은 사용할 수 없습니다.")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainRed)
                        .padding(.top, 5)
                case .tooShort:
                    Text("2글자 이하는 사용할 수 없습니다.")
                        .font(.scdream(.medium, size: 12))
                        .foregroundStyle(Color.mainRed)
                        .padding(.top, 5)
                default:
                    EmptyView()
                }
            }
            
            Spacer()
            
            MainOrangeButton(buttonTitle: "다음",
                             buttonColor: rootViewModel.validationState == .success ?
                             Color.mainOrange
                             : Color.mainGray2) {
                UIApplication.shared.endEditing(true)
                Task {
                    try? await Task.sleep(nanoseconds: 700_000_000) // 0.7초
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onNext()
                    }
                }
            }

            // MARK: - 활성화 로직
            .disabled(rootViewModel.validationState != .success) // 성공시 활성화
            .opacity(rootViewModel.validationState == .success ? 1.0 : 0.8)
            .background()
            
            // MARK: - 키보드 올라오면 공백과 함께 버튼 올라감
            .padding(.bottom, 20)
            .frame(maxHeight: .infinity, alignment: .bottom)
            
        }
        .padding(.horizontal, .contentPadding)
        .task {
            try? await Task.sleep(for: .seconds(0.3))
            isFocused = true
        }
    }
}

#Preview {
    NicknameSettingView {
        
    }
    .environmentObject(RootViewModel())
}
