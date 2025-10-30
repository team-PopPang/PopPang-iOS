//
//  ProfileView.swift
//  PopPang
//
//  Created by 김동현 on 9/16/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var coordinator: Coordinator<MainRoute, SheetRoute, OverlayRoute>
    @EnvironmentObject private var rootViewModel: RootViewModel
    @EnvironmentObject private var profileViewModel: ProfileViewModel
    @State private var isOn: Bool = false
    
    // MARK: - 이메일 관련
    @Environment(\.openURL) var openURL /// 다른 앱으로 연결을 위함
    private var emai = SupportEmail(toAddress: "poppang.app@gmail.com",
                                    title: "팝팡 문의사항",
                                    messageHeader: "문의사항을 입력해주세요.")
    
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
                                 size: 15,
                               
                ) {
                    coordinator.push(.profileSetting)
                }.padding(.horizontal, 24)
                
                Rectangle()
                    .fill(Color.mainGray5)
                    .frame(height: 2)
                
                NavigationButton(title: "키워드 알림",
                                 subTitle: "키워드의 팝업이 등록되면 안내해 드립니다.",
                                 buttonType: .toggle,
                                 isOn: $isOn
                ) {
                    
                }.padding(.horizontal, 24)
                
                NavigationButton(title: "공지사항",
                                 buttonType: .navigation,
                ) {
                    coordinator.push(.notification)
                }.padding(.horizontal, 24)
                
                NavigationButton(title: "문의하기",
                                 buttonType: .navigation,
                ) {
                    emai.send(openURL: openURL)
                }.padding(.horizontal, 24)
                
                NavigationButton(title: "서비스 이용약관",
                                 buttonType: .navigation,
                ) {
                    
                }.padding(.horizontal, 24)
            }
            .padding(.top, 20)
            
            
            Spacer()
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
         action: @escaping () -> Void,
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
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(Coordinator<MainRoute, SheetRoute, OverlayRoute>())
            .environmentObject(RootViewModel())
    }
}
