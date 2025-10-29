//
//  KeywordSettingView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI
import UserNotifications

struct KeywordSettingView: View {
    @EnvironmentObject private var rootViewModel: RootViewModel
    @State private var text: String = ""
    @FocusState private var isFocused: Bool
    
    // 중복 검사
    @State private var keywords: [String] = []
    
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
                    
                    // 공백이면 무시한다
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    
                    // 알림 권한이 없으면 알림 창을 띄우고 확인을 누르면 설정으로 이동시킨다
                    UNUserNotificationCenter.current().getNotificationSettings { settings in
                        switch settings.authorizationStatus {
                            
                        // MARK: - 권한이 거부된 경우
                        case .denied:
                            DispatchQueue.main.async {
                                // 알림
                                showNotificationPermissionAlert()
                            }
                            return
                        
                        // MARK: - 권한 요청 아직 안됨 -> 재요청
                        case .notDetermined:
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                                if granted {
                                    addKeyword(trimmed: trimmed)
                                } else {
                                    DispatchQueue.main.async {
                                        // 알림
                                        showNotificationPermissionAlert()
                                    }
                                }
                            }
                            
                        // MARK: - 권한이 허용된 경우
                        case .authorized, .provisional, .ephemeral:
                            DispatchQueue.main.async {
                                addKeyword(trimmed: trimmed)
                            }
                            
                        @unknown default:
                            break
                        }
                    }
                    
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
                            keywords.remove(at: index)
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

extension KeywordSettingView {
    func showNotificationPermissionAlert() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(title: "알림 허용",
                                       message: "키쿼드 알림을 받으려면 알림 권한을 허용해 주세요.",
                                       preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "설정으로 이동", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "다음에 하기", style: .default))
        rootVC.present(alert, animated: true)
    }
    
    func addKeyword(trimmed: String) {
        // 중복은 무시한다
        if keywords.contains(trimmed) { return }
        
        keywords.append(trimmed)
        text = ""
    }
}

#Preview {
    KeywordSettingView {}
        .environmentObject(RootViewModel())
}

