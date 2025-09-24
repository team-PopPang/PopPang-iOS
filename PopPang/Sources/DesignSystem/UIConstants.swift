//
//  UIConstants.swift
//  PopPang
//
//  Created by 김동현 on 9/20/25.
//

import SwiftUI

extension CGFloat {
    static let contentPadding: CGFloat = 24
    static let cornerRadius: CGFloat = 5
}

extension Font {
    static let largeTitle = Font.scdream(.extraBold, size: 18)
    static let bottomBtn = Font.scdream(.medium, size: 15)
    static let homeTitle = Font.scdream(.bold, size: 15)
    
    // MARK: - 1정렬
    static let title1 = Font.scdream(.medium, size: 12)
    static let caption1 = Font.scdream(.medium, size: 10)
    
    // MARK: - 2정렬
    static let title2 = Font.scdream(.medium, size: 10)
    static let caption2 = Font.scdream(.medium, size: 7)
    
    // MARK: - 3정렬
    static let title3 = Font.scdream(.medium, size: 8)
    static let caption3 = Font.scdream(.medium, size: 7)
    
    // MARK: - 탭 폰트
    // static let normal = Font.scdream(.light, size: 10)
    // static let tapped = Font.scdream(.bold, size: 20)
}

extension Color {
    // MARK: - Login
    static let kakao = Color(hex: "#FEE500")
    static let apple = Color(hex: "#1B1B1B")
    static let categoryOrange = Color(hex: "#FFF4EA")
    
    // MARK: - Main
    static let mainOrange = Color(hex: "#FF7A00")
    static let mainRed = Color(hex: "#DD0000")
    static let mainGreen = Color(hex: "#006813")
    static let mainWhite = Color(hex: "#F1F1F1")
    static let mainBlack = Color(hex: "#333333")
    static let mainTab = Color(hex: "#FFFFFF")
    
    // MARK: - Gray
    static let mainGray = Color(hex: "#777777")
    static let mainGray2 = Color(hex: "#AAAAAA")
    static let mainGray3 = Color(hex: "#CCCCCC")
    static let mainGray4 = Color(hex: "#F8F8F8")
}
