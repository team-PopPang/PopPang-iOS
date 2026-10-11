import SwiftUI

public extension CGFloat {
    static let contentPadding: CGFloat = 15
    static let cornerRadius: CGFloat = 5
}

/// 화면에서는 역할 이름(`PPColor`)을 쓴다. 이 팔레트는 `PPColor`가 가리키는 원래 색이다.
public extension Color {
    static let kakao = Color(hex: "#FEE500")
    static let apple = Color(hex: "#1B1B1B")
    static let categoryOrange = Color(hex: "#FFF4EA")
    static let mainOrange = Color(hex: "#FF7A00")
    static let subOrange = Color(hex: "#DE5C00")
    static let subOrange2 = Color(hex: "#FFF6ED")
    static let mainRed = Color(hex: "#DD0000")
    static let mainGreen = Color(hex: "#006813")
    static let mainWhite = Color(hex: "#F1F1F1")
    static let subWhite = Color(hex: "#FFFFFF")
    /// `mainGray3`과 같은 색이다.
    static let subWhite2 = mainGray3
    static let subWhite3 = Color(hex: "#F2F2F2")
    static let mainBlack = Color(hex: "#333333")
    static let subBlack = Color(hex: "#000000")
    static let subBlack2 = Color(hex: "#323232")
    static let subBlack3 = Color(hex: "#3D1D1C")
    /// `subWhite`와 같은 색이다.
    static let bestPostTitle = subWhite
    /// `mainGray5`와 같은 색이다.
    static let bestPostAddress = mainGray5
    static let mainGray = Color(hex: "#777777")
    static let mainGray2 = Color(hex: "#AAAAAA")
    static let mainGray3 = Color(hex: "#CCCCCC")
    static let mainGray4 = Color(hex: "#F8F8F8")
    static let mainGray5 = Color(hex: "#EEEEEE")
    static let mainGray6 = Color(hex: "#999999")
    static let mainGray7 = Color(hex: "#F3F4F6")
    static let mainGray8 = Color(hex: "#DDDDDD")
    static let mainGray9 = Color(hex: "#666666")
}
