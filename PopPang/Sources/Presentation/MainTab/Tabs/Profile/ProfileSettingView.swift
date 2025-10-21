//
//  ProfileSettingView.swift
//  PopPang
//
//  Created by 김동현 on 10/21/25.
//

import SwiftUI

struct ProfileSettingView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String = ""
    @FocusState private var isFocused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            
            // MARK: - 닉네임 설정
            HStack(spacing: 10) {
                RoundedTextField(placeholder: "닉네임을 입력해 주세요",
                                 text: $rootViewModel.nickname,
                                 validationState: rootViewModel.validationState
                )
                .focused($isFocused)
                
                Button {
                    rootViewModel.send(action: .checkNickname)
                } label: {
                    Text("중복확인")
                        .font(.scdream(.medium, size: 12))
                        .frame(width: 100, height: 48)
                        .foregroundStyle(Color.mainWhite)
                        .background(Color.mainOrange)
                        .cornerRadius(5)
                }
            }
            
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
            
            // MARK: - 로그아웃
            Button {
                
            } label: {
                Text("로그아웃")
                    .frame(height: 22)
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.subBlack)
            }
            .padding(.top, 20)
            
            // MARK: - 회원탈퇴
            Button {
                 
            } label: {
                Text("회원탈퇴")
                    .frame(height: 22)
                    .ppStyleFont(.scdream(.regular, size: 10))
                    .foregroundStyle(Color.mainGray2)
            }
            .padding(.top, 4)
            
            Spacer()
            
            MainOrangeButton(buttonTitle: "다음",
                             buttonColor: rootViewModel.validationState == .success ?
                             Color.mainOrange
                             : Color.mainGray2) {
                UIApplication.shared.endEditing(true)
                dismiss()
            }
            
            // MARK: - 활성화 로직
            .disabled(rootViewModel.validationState != .success) // 성공시 활성화
            .opacity(rootViewModel.validationState == .success ? 1.0 : 0.8)
            
            // MARK: - 키워드 올라오면 공백과 함꼐 버튼 올라옴
            .padding(.bottom, 20)
        }
        .padding(.top, 24)
        .padding(.horizontal, 24)
        .toolbar {
            // 커스텀 타이틀
            ToolbarItem(placement: .principal) {
                Text("프로필 설정")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .padding(.top, 10)
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    NavigationStack {
        ProfileSettingView()
            .navigationTitle("프로필 설정") // Preview에서만 타이틀 보이게
            .navigationBarTitleDisplayMode(.inline)
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
            .environmentObject(RootViewModel())
    }
}
