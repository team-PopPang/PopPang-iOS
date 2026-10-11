import SwiftUI

/// 화면에서 쓰는 색을 역할 이름으로 고른다.
/// 값은 기존 팔레트(`Color.mainOrange` 등)를 그대로 가리키며, 역할은 현재 화면에서 각 색이 쓰이는 방식을 기준으로 정했다.
/// UIKit에서는 `PPColor.brand.uiColor`처럼 쓴다.
public enum PPColor {
    /// 주요 버튼 배경, 강조 글자·아이콘
    public static let brand = Color.mainOrange
    /// 브랜드 색을 옅게 깐 배경
    public static let brandSubtle = Color.subOrange2

    /// 본문 글자
    public static let textPrimary = Color.mainBlack
    /// 가장 진한 글자
    public static let textStrong = Color.subBlack
    /// 보조 설명 글자
    public static let textSecondary = Color.mainGray
    /// 안내·비활성 글자
    public static let textTertiary = Color.mainGray2
    /// 브랜드 색 배경 위의 글자
    public static let textOnBrand = Color.mainWhite

    /// 기본 화면 배경
    public static let background = Color.subWhite
    /// 구역을 나누는 옅은 회색 배경
    public static let backgroundSecondary = Color.mainGray4

    /// 입력창·카드 테두리
    public static let border = Color.mainGray3
    /// 구분선
    public static let divider = Color.mainGray5

    /// 오류 안내
    public static let error = Color.mainRed
    /// 성공 안내
    public static let success = Color.mainGreen
}
