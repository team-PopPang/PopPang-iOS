//
//  ColorSystem.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import SwiftUI

extension Color {
    
    ///
    /// - Parameters:
    ///   - hex: 색상 Hex 문자열. `#` 포함/미포함 모두 가능 (예: "#FF5733" 또는 "FF5733").
    ///   - alpha: 투명도 값 (0.0 ~ 1.0). 기본값은 1.0 (불투명).
    init(hex: String, alpha: Double = 1.0) {
        var hexFormatted = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexFormatted.hasPrefix("#") {
            hexFormatted.removeFirst()
        }
        
        var rgbValue: UInt64 = 0
        Scanner(string: hexFormatted).scanHexInt64(&rgbValue)
        
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// MARK: - Custom Color Set
//extension Color {
//    
//    // MARK: - Login
//    static let kakao = Color(hex: "#FEE500")
//    static let apple = Color(hex: "#1B1B1B")
//    
//    // MARK: - Main
//    static let mainOrange = Color(hex: "#FF7A00")
//    static let mainRed = Color(hex: "#DD0000")
//    static let mainGreen = Color(hex: "#006813")
//    static let mainWhite = Color(hex: "#F1F1F1")
//    static let mainBlack = Color(hex: "#333333")
//    
//    // MARK: - Gray
//    static let mainGray = Color(hex: "#777777")
//    static let mainGray2 = Color(hex: "#AAAAAA")
//    static let mainGray3 = Color(hex: "#CCCCCC")
//    static let mainGray4 = Color(hex: "#F8F8F8")
//    
//    // MARK: - TextField
//    static let textFieldPlaceHolder = Color(hex: "#AAAAAA")
//    static let textFieldFg = Color(hex: "#333333")
//    static let textFieldBg = Color(hex: "#F3F4F6")
//    static let textFieldGr = Color(hex: "#006813")
//    static let textFieldRe = Color(hex: "#DD0000")
//    
//    
//    // MARK: - Gray
////    static let Gray000 = Color(hex: "#EFEFEF")
////    static let Gray100 = Color(hex: "#B0AEB3")
////    static let Gray200 = Color(hex: "#8B888F")
////    static let Gray300 = Color(hex: "#67646C")
////    static let Gray500 = Color(hex: "#454348")
////    static let Gray700 = Color(hex: "#252427")
////    static let Gray900 = Color(hex: "#111113")
//}
