import CoreGraphics

/// 네이티브 광고 내부 콘텐츠 여백입니다.
public struct AdNativeAdInsets: Hashable, Sendable {
    /// 상단 여백입니다.
    public let top: CGFloat

    /// 좌측 여백입니다.
    public let leading: CGFloat

    /// 하단 여백입니다.
    public let bottom: CGFloat

    /// 우측 여백입니다.
    public let trailing: CGFloat

    /// 네이티브 광고 콘텐츠 여백을 생성합니다.
    public init(
        top: CGFloat,
        leading: CGFloat,
        bottom: CGFloat,
        trailing: CGFloat
    ) {
        self.top = top
        self.leading = leading
        self.bottom = bottom
        self.trailing = trailing
    }
}

/// 네이티브 광고 뷰의 배치, 비율, 글자 크기를 정의하는 레이아웃 값입니다.
public struct AdNativeAdLayout: Hashable, Sendable {
    /// 광고 미디어와 텍스트 영역을 쌓는 방향입니다.
    public enum Axis: String, Hashable, Sendable {
        case vertical
        case horizontal
    }

    public let axis: Axis
    public let mediaAspectRatio: CGFloat
    public let horizontalMediaWidthRatio: CGFloat
    public let cornerRadius: CGFloat
    public let borderWidth: CGFloat
    public let contentInsets: AdNativeAdInsets
    public let headlineFontSize: CGFloat
    public let badgeFontSize: CGFloat
    public let callToActionFontSize: CGFloat
    public let callToActionHeight: CGFloat

    public init(
        axis: Axis,
        mediaAspectRatio: CGFloat,
        horizontalMediaWidthRatio: CGFloat = 0.38,
        cornerRadius: CGFloat = 8,
        borderWidth: CGFloat = 1,
        contentInsets: AdNativeAdInsets,
        headlineFontSize: CGFloat,
        badgeFontSize: CGFloat = 10,
        callToActionFontSize: CGFloat,
        callToActionHeight: CGFloat = 31
    ) {
        self.axis = axis
        self.mediaAspectRatio = max(mediaAspectRatio, 0.1)
        self.horizontalMediaWidthRatio = min(max(horizontalMediaWidthRatio, 0.2), 0.6)
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.contentInsets = contentInsets
        self.headlineFontSize = headlineFontSize
        self.badgeFontSize = badgeFontSize
        self.callToActionFontSize = callToActionFontSize
        self.callToActionHeight = callToActionHeight
    }
}

public extension AdNativeAdLayout {
    static let grid = AdNativeAdLayout(
        axis: .vertical,
        mediaAspectRatio: 0.82,
        contentInsets: AdNativeAdInsets(top: 9, leading: 8, bottom: 9, trailing: 8),
        headlineFontSize: 13,
        callToActionFontSize: 12
    )

    static let compactBanner = AdNativeAdLayout(
        axis: .horizontal,
        mediaAspectRatio: 1,
        horizontalMediaWidthRatio: 0.34,
        contentInsets: AdNativeAdInsets(top: 10, leading: 10, bottom: 10, trailing: 10),
        headlineFontSize: 14,
        callToActionFontSize: 12,
        callToActionHeight: 30
    )
}
