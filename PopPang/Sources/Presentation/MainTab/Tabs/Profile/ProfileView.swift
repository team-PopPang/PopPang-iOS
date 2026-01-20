//
//  ProfileView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>
    @EnvironmentObject private var rootViewModel: RootViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var tempIsOn: Bool = false
    
    // MARK: - 이메일 관련
    @Environment(\.openURL) var openURL /// 다른 앱으로 연결을 위함
    private var email = SupportEmail(toAddress: "poppang.app@gmail.com",
                                    title: "팝팡 문의사항",
                                    messageHeader: "문의사항을 입력해주세요.")
    
    // MARK: - 버전 정보
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    
    var body: some View {
        VStack(spacing: 0) {
            
 
            // MARK: - 네비게이션바
            CustomNavigationBar {
                Text("마이페이지")
                    .ppStyleFont(.scdream(.medium, size: 18))
                    .foregroundStyle(Color.mainBlack)
                
                Spacer()
                
                IconButton {
                    coordinator.push(.alert(uuid: rootViewModel.user?.userUuid ?? ""))
                }
            }
            
            VStack(spacing: 20) {
                NavigationButton(title: rootViewModel.user?.nickname ?? "홍길동",
                                 buttonType: .navigation,
                                 font: .bold,
                                 size: 15
                ) {
                    coordinator.push(.profileSetting)
                }.padding(.horizontal, 24)
                
                Rectangle()
                    .fill(Color.mainGray5)
                    .frame(height: 2)
                
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("키워드 알림")
                            .ppStyleFont(.scdream(.regular, size: 12))
                        Text("키워드의 팝업이 등록되면 안내해 드립니다.")
                            .ppStyleFont(.scdream(.light, size: 10))
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: $tempIsOn)
                        .labelsHidden()
                        .tint(.mainOrange)
                        .onAppear {
                            tempIsOn = profileViewModel.isAlerted
                        }
                        .onChange(of: tempIsOn) { _, newValue in
                            handleToggleChange(newValue)
                        }
                }
                .padding(.horizontal, 24)
                
                NavigationButton(title: "공지사항",
                                 buttonType: .navigation
                ) {
                    coordinator.push(.notification)
                }.padding(.horizontal, 24)
                
                NavigationButton(title: "문의하기",
                                 buttonType: .navigation
                ) {
                    email.send(openURL: openURL)
                }.padding(.horizontal, 24)
                
                NavigationButton(title: "서비스 이용약관",
                                 buttonType: .navigation
                ) {
                    coordinator.push(.service)
                }.padding(.horizontal, 24)
            }
            .padding(.top, 20)
            
            
            Spacer()
            
            HStack {
                Spacer()
                Text("버전: \(appVersion)")
                    .ppStyleFont(.scdream(.regular, size: 12))
                    .foregroundStyle(Color.mainGray2)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
    }
    
    private func handleToggleChange(_ newValue: Bool) {
        // MARK: - 알림 권한 인증
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
                // MARK: - 권한이 거부된 경우
            case .denied:
                DispatchQueue.main.async {
                    tempIsOn = false
                    AlertManager.shared.showPermissionAlert()
                }
                
                // MARK: - 권한 요청 아직 안됨 -> 재요청
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    DispatchQueue.main.async {
                        if granted {
                            // 권한 허용 & 현재 토글 상태 서버 반영
                            profileViewModel.send(action: .alertStatus)
                        } else {
                            // 권한 거부, 토글 상태 되돌리기
                            tempIsOn = false
                            AlertManager.shared.showPermissionAlert()
                        }
                    }
                }
                
                // MARK: - 권한이 허용된 경우
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    // 토글 변경
                    profileViewModel.isAlerted = newValue
                    profileViewModel.send(action: .alertStatus)
                }
            @unknown default:
                break
            }
        }
    }
}

struct NavigationButton: View {
    enum ButtonType {
        case navigation
        case toggle
    }
    var title: String
    var subTitle: String?
    var buttonType: ButtonType
    var font: UIFont.SCDream
    var size: CGFloat
    var color: Color
    var action: (() -> Void)
    @Binding var isOn: Bool
    
    // MARK: - Navigation 전용
    init(title: String,
         subTitle: String? = nil,
         buttonType: ButtonType,
         font: UIFont.SCDream = .regular,
         size: CGFloat = 12,
         color: Color = .subBlack,
         action: @escaping () -> Void
    ) {
        self.title = title
        self.subTitle = subTitle
        self.buttonType = buttonType
        self.font = font
        self.size = size
        self.color = color
        self.action = action
        self._isOn = .constant(false)
    }
    
    // MARK: - Toggle 전용
    init(
          title: String,
          subTitle: String? = nil,
          buttonType: ButtonType,
          font: UIFont.SCDream = .regular,
          size: CGFloat = 12,
          color: Color = .subBlack,
          isOn: Binding<Bool>,
          action: @escaping () -> Void
      ) {
          self.title = title
          self.subTitle = subTitle
          self.buttonType = buttonType
          self.font = font
          self.size = size
          self.color = color
          self._isOn = isOn
          self.action = action
      }
    
    private var content: some View {
        HStack {
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .ppStyleFont(.scdream(font,
                                          size: size))
                
                if let subTitle = subTitle {
                    Text(subTitle)
                        .ppStyleFont(.scdream(.light,
                                              size: 10))
                }
            }
            .foregroundStyle(color)
                
            Spacer()
            
            if buttonType == .navigation {
                Image("navigationButton")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 16, height: 16)
            } else {
                Toggle("", isOn: $isOn)
                    .labelsHidden()
                    .tint(.mainOrange)
            }
        }
    }
    
    var body: some View {
        
        if buttonType == .navigation {
            Button {
                action()
            } label: {
                content
            }
        } else {
            content
                .onChange(of: isOn) { _, _ in
                    action()
                }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute, FullScreenRoute>())
            .environmentObject(RootViewModel())
            .environmentObject(ProfileViewModel(userUuid: "", isAlerted: true))
    }
}
