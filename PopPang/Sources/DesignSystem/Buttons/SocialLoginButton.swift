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
        
        var imageName: String {
            switch self {
            case .kakao: return "Logo Kakao"
            case .apple: return "Logo Apple"
            }
        }
        
        var title: String {
            switch self {
            case .kakao: return "카카오 로그인"
            case .apple: return "Apple 로그인"
            }
        }
        
        var fgColor: Color {
            switch self {
            case .kakao: return .mainBlack
            case .apple: return .mainWhite
            }
        }
        
        var bgColor: Color {
            switch self {
            case .kakao: return .kakao
            case .apple: return .apple
            }
        }
        
        var iconColor: Color {
            switch self {
            case .kakao: return .mainBlack
            case .apple: return .mainWhite
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
                    .renderingMode(.template)
                    .foregroundColor(type.iconColor)
                    .scaledToFit()
                    .frame(width: size, height: size)
                Text(type.title)
                    .font(.scdream(.bold, size: 16))
            }
            .padding()
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .foregroundStyle(type.fgColor)
        .background(type.bgColor)
        .cornerRadius(cornerRadius)
    }
}
