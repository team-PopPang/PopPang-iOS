import SwiftUI
import UIKit

/// 글자 크기·행간·자간을 묶은 텍스트 스타일.
/// 크기 단계는 기존 화면에서 쓰는 S-CoreDream 크기를 기준으로 정했다. 굵기는 스타일마다 기본값이 있고 바꿀 수 있다.
/// `Text("제목").ppTextStyle(.title3)`처럼 쓴다.
public enum PPTextStyle: CaseIterable, Sendable {
    /// 26pt. 큰 강조 문구
    case display
    /// 20pt
    case title1
    /// 18pt
    case title2
    /// 17pt. 화면·구역 제목
    case title3
    /// 15pt
    case body1
    /// 14pt. 버튼 글자
    case body2
    /// 13pt
    case body3
    /// 12pt. 가장 많이 쓰는 본문 크기
    case body4
    /// 11pt
    case caption1
    /// 10pt
    case caption2
    /// 9pt
    case caption3

    /// 글자 크기(pt)
    public var size: CGFloat {
        switch self {
        case .display:
            26
        case .title1:
            20
        case .title2:
            18
        case .title3:
            17
        case .body1:
            15
        case .body2:
            14
        case .body3:
            13
        case .body4:
            12
        case .caption1:
            11
        case .caption2:
            10
        case .caption3:
            9
        }
    }

    /// 굵기를 따로 넘기지 않을 때 쓰는 굵기
    public var defaultWeight: UIFont.SCDream {
        switch self {
        case .display:
            .extraBold
        case .title1, .title2, .title3:
            .bold
        case .body1, .body2:
            .medium
        case .body3, .body4, .caption1, .caption3:
            .regular
        case .caption2:
            .light
        }
    }

    /// 글자 크기 대비 행간 배수. `ppStyleFont`의 기본값과 같다.
    public var lineHeight: CGFloat { 1.4 }

    /// 글자 크기 대비 자간 비율. `ppStyleFont`의 기본값과 같다.
    public var letterSpacing: CGFloat { 0.02 }

    /// UIKit에서 쓰는 글꼴
    /// - Parameter weight: 스타일 기본 굵기 대신 쓸 굵기
    public func uiFont(weight: UIFont.SCDream? = nil) -> UIFont {
        .scdream(weight ?? defaultWeight, size: size)
    }
}

public extension View {
    /// 텍스트 스타일의 글꼴·행간·자간을 적용한다.
    /// - Parameter weight: 스타일 기본 굵기 대신 쓸 굵기
    func ppTextStyle(_ style: PPTextStyle, weight: UIFont.SCDream? = nil) -> some View {
        ppStyleFont(
            style.uiFont(weight: weight),
            lineHeight: style.lineHeight,
            letterSpacing: style.letterSpacing
        )
    }
}
