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
    ///
    /// - Parameters:
    ///   - top: 상단 여백입니다.
    ///   - leading: 좌측 여백입니다.
    ///   - bottom: 하단 여백입니다.
    ///   - trailing: 우측 여백입니다.
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
///
/// 실제 크기는 호출 지점의 `.frame(...)`, 리스트 셀 크기, 부모 제약으로 결정되고,
/// 이 타입은 그 안에서 미디어/텍스트/버튼이 어떻게 배치될지만 정의합니다.
public struct AdNativeAdLayout: Hashable, Sendable {
    /// 광고 미디어와 텍스트 영역을 쌓는 방향입니다.
    public enum Axis: String, Hashable, Sendable {
        /// 미디어 영역 위에 텍스트/버튼 영역을 세로로 쌓습니다.
        case vertical

        /// 미디어 영역과 텍스트/버튼 영역을 가로로 배치합니다.
        case horizontal
    }

    /// 미디어 영역과 텍스트 영역을 배치하는 방향입니다.
    public let axis: Axis

    /// 세로 레이아웃에서 미디어 영역의 가로/세로 비율입니다.
    public let mediaAspectRatio: CGFloat

    /// 가로 레이아웃에서 전체 너비 중 미디어 영역이 차지하는 비율입니다.
    public let horizontalMediaWidthRatio: CGFloat

    /// 광고 카드 모서리 반경입니다.
    public let cornerRadius: CGFloat

    /// 광고 카드 테두리 두께입니다.
    public let borderWidth: CGFloat

    /// 제목, 광고 배지, CTA 버튼 영역의 내부 여백입니다.
    public let contentInsets: AdNativeAdInsets

    /// 광고 제목 글자 크기입니다.
    public let headlineFontSize: CGFloat

    /// "광고" 배지 글자 크기입니다.
    public let badgeFontSize: CGFloat

    /// CTA 버튼 글자 크기입니다.
    public let callToActionFontSize: CGFloat

    /// CTA 버튼 높이입니다.
    public let callToActionHeight: CGFloat

    /// 네이티브 광고 레이아웃 값을 생성합니다.
    ///
    /// - Parameters:
    ///   - axis: 광고 미디어와 텍스트 영역을 배치하는 방향입니다.
    ///   - mediaAspectRatio: 세로 레이아웃에서 미디어 영역의 가로/세로 비율입니다. 최소 `0.1`로 보정됩니다.
    ///   - horizontalMediaWidthRatio: 가로 레이아웃에서 미디어 영역의 너비 비율입니다. `0.2...0.6` 범위로 보정됩니다.
    ///   - cornerRadius: 광고 카드 모서리 반경입니다.
    ///   - borderWidth: 광고 카드 테두리 두께입니다.
    ///   - contentInsets: 제목, 광고 배지, CTA 버튼 영역의 내부 여백입니다.
    ///   - headlineFontSize: 광고 제목 글자 크기입니다.
    ///   - badgeFontSize: "광고" 배지 글자 크기입니다.
    ///   - callToActionFontSize: CTA 버튼 글자 크기입니다.
    ///   - callToActionHeight: CTA 버튼 높이입니다.
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
    /// 2열 그리드 셀에 맞춘 기본 네이티브 광고 레이아웃입니다.
    static let grid = AdNativeAdLayout(
        axis: .vertical,
        mediaAspectRatio: 0.82,
        contentInsets: AdNativeAdInsets(top: 9, leading: 8, bottom: 9, trailing: 8),
        headlineFontSize: 13,
        callToActionFontSize: 12
    )

    /// 리스트나 상세 화면 중간의 낮은 배너 영역에 맞춘 가로형 레이아웃입니다.
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
