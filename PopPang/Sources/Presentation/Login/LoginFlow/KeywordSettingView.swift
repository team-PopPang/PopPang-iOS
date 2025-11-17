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
    
    // 중복 검사
    @State private var keywords: [String] = []
    
    // 최대 키워드 개수
    private let maxKeywordCount: Int = 5
    
    // 다음 스탭 활성화 유무
    private var isNextEnabled: Bool {
        !keywords.isEmpty
    }
    
    var onNext: () -> Void
    var body: some View {

        VStack(alignment: .leading) {
            
            HStack {
                VStack(alignment: .leading, spacing: 10) {
                    Text("키워드를\n입력해주세요.")
                        .font(.scdream(.bold, size: 17))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("등록된 키워드에 맞춰 알림을 받아볼 수 있어요.")
                            
                            .foregroundStyle(Color.mainGray)
                        Text("(최대 5개 등록 가능)")
                    }
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(Color.mainGray)
                }
                
                Spacer()
                
                /*
                Text("\(keywords.count)/\(maxKeywordCount)")
                    .font(.scdream(.medium, size: 12))
                    .foregroundStyle(isNextEnabled ? Color.mainGreen : Color.mainRed)
                 */
            }
            .padding(.top, 50)
            
            HStack(spacing: 10) {
                KeywordTextField(placeholder: "ex) 화장품, 애니메이션",
                                 text: $text)
                
                Button {
                    
                    // 공백이면 무시한다
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    
                    // 키워드는 최대 5개까지 가능하다
                    if keywords.count >= maxKeywordCount {
                        AlertManager.shared.showKeywordLimitAlert()
                        return
                    }
                    
                    // 알림 권한 체크
                    alertCheck(trimmed: trimmed)
                    
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
            
            MainOrangeButton(buttonTitle: "다음",
                             buttonColor: isNextEnabled ? Color.mainOrange : Color.mainGray2) {
                rootViewModel.send(action: .setalertList(keywords))
                rootViewModel.send(action: .register)
            }
            // MARK: - 활성화 로직
            .disabled(!isNextEnabled)
            .opacity(isNextEnabled ? 1.0 : 0.8)
            
            // 키보드 올라오면 공백과 함께 버튼 올라감
            .padding(.bottom, 20)
        }
        .padding(.horizontal, .contentPadding)
    }
}

extension KeywordSettingView {

    func addKeyword(trimmed: String) {
        // 중복은 무시한다
        if keywords.contains(trimmed) { return }
        
        keywords.append(trimmed)
        text = ""
    }
    
    func alertCheck(trimmed: String) {
        // 알림 권한이 없으면 알림 창을 띄우고 확인을 누르면 설정으로 이동시킨다
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
                
            // MARK: - 권한이 거부된 경우
            case .denied:
                DispatchQueue.main.async {
                    // 알림
                    AlertManager.shared.showPermissionAlert()
                }
                return
            
            // MARK: - 권한 요청 아직 안됨 -> 재요청
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if granted {
                        addKeyword(trimmed: trimmed)
                        rootViewModel.send(action: .setIsAlertedUser(true))
                    } else {
                        DispatchQueue.main.async {
                            // 알림
                            AlertManager.shared.showPermissionAlert()
                        }
                    }
                }
                
            // MARK: - 권한이 허용된 경우
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    addKeyword(trimmed: trimmed)
                    rootViewModel.send(action: .setIsAlertedUser(true))
                }
                
            @unknown default:
                break
            }
        }
    }
}

#Preview {
    KeywordSettingView {}
        .environmentObject(RootViewModel())
}

