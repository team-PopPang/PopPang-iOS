//
//  UIFont.swift
//  PopPang
//
//  Created by 김동현 on 9/14/25.
//

import UIKit
import SwiftUI

extension UIFont {
    enum SCDream: String {
        case thin       = "S-CoreDream-1Thin"
        case extraLight = "S-CoreDream-2ExtraLight"
        case light      = "S-CoreDream-3Light"
        case regular    = "S-CoreDream-4Regular"
        case medium     = "S-CoreDream-5Medium"
        case bold       = "S-CoreDream-6Bold"
        case extraBold  = "S-CoreDream-7ExtraBold"
        case heavy      = "S-CoreDream-8Heavy"
        case black      = "S-CoreDream-9Black"
    }
    
    /// SCDream 커스텀 폰트를 반환합니다
    /// - Parameters:
    ///   - weight: SCDream enum
    ///   - size: 폰트 크기
    /// - Returns: UIFont 인스턴스
    static func scdream(_ weight: SCDream, size: CGFloat) -> UIFont {
        return UIFont(name: weight.rawValue, size: size)!
    }
}

extension Font {
    static func scdream(_ weight: UIFont.SCDream, size: CGFloat) -> Font {
        if let uiFont = UIFont(name: weight.rawValue, size: size) {
            return Font(uiFont)
        } else {
            print("⚠️ 폰트 로드 실패 → fallback")
            return .system(size: size) // fallback
        }
    }
}


struct FontTestView: View {
    var body: some View {
        VStack {
            Text("Hello World")
            
            Text("dream1")
                .font(.scdream(.thin, size: 24))
            
            Text("dream3")
                .font(.scdream(.light, size: 24))
            
            Text("dream5")
                .font(.scdream(.medium, size: 24))
            
            Text("dream7")
                .font(.scdream(.extraBold, size: 24))
            
            Text("dream9")
                .font(.scdream(.black, size: 24))
        }
    }
}

#Preview {
    FontTestView()
}
