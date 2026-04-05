//
//  SocialLoginButton.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

struct SocialLoginButton: View {
    enum SocialType {
        case kakao
        case apple
        case google
        
        var imageName: String {
            switch self {
            case .kakao: return "Logo Kakao"
            case .apple: return "Logo Apple"
            case .google: return "Logo Google"
            }
        }
        
        var title: String {
            switch self {
            case .kakao:
                return NSLocalizedString("login.social.kakao", comment: "Login button title for Kakao")
            case .apple:
                return NSLocalizedString("login.social.apple", comment: "Login button title for Apple")
            case .google:
                return NSLocalizedString("login.social.google", comment: "Login button title for Google")
            }
        }
        
        var fgColor: Color {
            switch self {
            case .kakao: return .subBlack3
            case .apple: return .subWhite
            case .google: return .mainBlack
            }
        }
        
        var bgColor: Color {
            switch self {
            case .kakao: return .kakao
            case .apple: return .apple
            case .google: return .subWhite
            }
        }
        
        var iconColor: Color {
            switch self {
            case .kakao: return .mainBlack
            case .apple: return .mainWhite
            case .google: return .clear
            }
        }
    }
    
    let type: SocialType
    let size: CGFloat
    let cornerRadius: CGFloat
    let action: () -> Void
    
    init(type: SocialType,
         size: CGFloat = 20,
         cornerRadius: CGFloat = 5,
         action: @escaping () -> Void
    ) {
        self.type = type
        self.size = size
        self.cornerRadius = cornerRadius
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(type.imageName)
                    .resizable()
                    .renderingMode(type == .google ? .original : .template)
                    .foregroundColor(type.iconColor)
                    .scaledToFit()
                    .frame(width: size, height: size)
                Text(type.title)
                    .font(.scdream(.medium, size: 15))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(Rectangle())
        }
        .foregroundStyle(type.fgColor)
        .background(type.bgColor)
        .cornerRadius(cornerRadius)
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(type == .google ? Color.subBlack : .clear, lineWidth: 0.5)
        }
    }
}

#Preview {
    SocialLoginButton(type: .apple) {
        
    }
    
    SocialLoginButton(type: .kakao) {
        
    }
    
    SocialLoginButton(type: .google) {
        
    }
}
