import CoreGraphics

/// 여백과 간격 값.
/// 기존 화면에서 많이 쓰는 값만 골랐다. 화면에서는 숫자 대신 이 값을 쓰고, 목록에 없는 값이 필요하면 먼저 여기에 추가한다.
public enum PPSpacing {
    public static let s4: CGFloat = 4
    public static let s5: CGFloat = 5
    public static let s8: CGFloat = 8
    public static let s10: CGFloat = 10
    public static let s12: CGFloat = 12
    public static let s15: CGFloat = 15
    public static let s20: CGFloat = 20
    public static let s24: CGFloat = 24

    /// 화면 좌우 여백. 기존 `CGFloat.contentPadding`과 같다.
    public static let screenHorizontal: CGFloat = .contentPadding
}

/// 모서리 둥글기 값. 알약 모양은 `Capsule()`을 쓴다.
public enum PPRadius {
    /// 버튼·입력창. 기존 `CGFloat.cornerRadius`와 같다.
    public static let small: CGFloat = .cornerRadius
    /// 카드·이미지
    public static let medium: CGFloat = 10
    /// 시트·큰 카드
    public static let large: CGFloat = 16
}
