import SwiftUI

/// PopPang 버튼 모양. `Button("다음") { }.buttonStyle(.ppPrimary)`처럼 쓴다.
/// `primary`와 `outline`은 `MainOrangeButton`의 기본·반전 모양과 같고, 눌림 효과는 `PressableButtonStyle`과 같다.
public struct PPButtonStyle: ButtonStyle {
    /// 버튼 종류
    public enum Kind: Sendable {
        /// 브랜드 색 배경
        case primary
        /// 흰 배경에 브랜드 색 테두리
        case outline
        /// 배경 없이 브랜드 색 글자만
        case text
    }

    /// 버튼 높이와 글자 크기
    public enum Size: Sendable {
        /// 높이 56pt, 14pt 글자
        case large
        /// 높이 44pt, 14pt 글자
        case medium
        /// 높이 32pt, 12pt 글자
        case small

        var height: CGFloat {
            switch self {
            case .large:
                56
            case .medium:
                44
            case .small:
                32
            }
        }

        var textStyle: PPTextStyle {
            switch self {
            case .large, .medium:
                .body2
            case .small:
                .body4
            }
        }
    }

    @Environment(\.isEnabled) private var isEnabled

    private let kind: Kind
    private let size: Size
    private let fillsWidth: Bool

    /// - Parameter fillsWidth: 가로를 꽉 채울지 여부
    public init(_ kind: Kind, size: Size = .large, fillsWidth: Bool = true) {
        self.kind = kind
        self.size = size
        self.fillsWidth = fillsWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        // 버튼 글자는 한 줄이라 MainOrangeButton처럼 행간·자간을 넣지 않는다.
        configuration.label
            .ppStyleFont(size.textStyle.uiFont(weight: .bold), lineHeight: 1, letterSpacing: 0)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, kind == .text ? 0 : PPSpacing.s20)
            .frame(maxWidth: fillsWidth ? .infinity : nil)
            .frame(height: size.height)
            .background(backgroundColor, in: .rect(cornerRadius: PPRadius.small))
            .overlay {
                if kind == .outline {
                    RoundedRectangle(cornerRadius: PPRadius.small)
                        .stroke(PPColor.brand, lineWidth: 1)
                }
            }
            .contentShape(.rect)
            .opacity(isEnabled ? 1 : 0.4)
            .ppPressFeedback(isPressed: configuration.isPressed)
    }

    private var foregroundColor: Color {
        switch kind {
        case .primary:
            PPColor.textOnBrand
        case .outline, .text:
            PPColor.brand
        }
    }

    private var backgroundColor: Color {
        switch kind {
        case .primary:
            PPColor.brand
        case .outline:
            PPColor.background
        case .text:
            .clear
        }
    }
}

public extension ButtonStyle where Self == PPButtonStyle {
    /// 브랜드 색 배경의 큰 버튼. 가로를 꽉 채운다.
    static var ppPrimary: PPButtonStyle { PPButtonStyle(.primary) }

    /// 흰 배경에 브랜드 색 테두리를 두른 큰 버튼. 가로를 꽉 채운다.
    static var ppOutline: PPButtonStyle { PPButtonStyle(.outline) }

    /// 배경 없이 브랜드 색 글자만 있는 버튼. 누를 수 있는 높이 44pt를 확보한다.
    static var ppText: PPButtonStyle { PPButtonStyle(.text, size: .medium, fillsWidth: false) }

    /// 종류·크기·너비를 직접 고른다.
    static func pp(
        _ kind: PPButtonStyle.Kind,
        size: PPButtonStyle.Size = .large,
        fillsWidth: Bool = true
    ) -> PPButtonStyle {
        PPButtonStyle(kind, size: size, fillsWidth: fillsWidth)
    }
}
