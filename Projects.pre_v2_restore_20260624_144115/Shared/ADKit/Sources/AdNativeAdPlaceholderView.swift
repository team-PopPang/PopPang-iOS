import SwiftUI

/// Preview-safe 광고 placeholder 뷰입니다.
///
/// 실제 Google Mobile Ads 런타임 대신, 광고가 삽입될 자리와 레이아웃을 확인할 때 사용합니다.
public struct AdNativeAdPlaceholderView: View {
    private let layout: AdNativeAdLayout

    public init(layout: AdNativeAdLayout = .grid) {
        self.layout = layout
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: layout.cornerRadius)
            .fill(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: layout.cornerRadius)
                    .stroke(Color.gray.opacity(0.2), lineWidth: layout.borderWidth)
            }
            .overlay {
                switch layout.axis {
                case .vertical:
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.12))
                            .aspectRatio(layout.mediaAspectRatio, contentMode: .fit)
                            .overlay(alignment: .topLeading) {
                                adBadge
                                    .padding(.top, layout.contentInsets.top)
                                    .padding(.leading, layout.contentInsets.leading)
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: max(layout.headlineFontSize + 3, 14))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.8))
                                .frame(height: layout.callToActionHeight)
                        }
                        .padding(.top, 8)
                        .padding(.horizontal, layout.contentInsets.leading)
                        .padding(.bottom, layout.contentInsets.bottom)
                    }
                case .horizontal:
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.12))
                            .frame(maxWidth: .infinity)
                            .overlay(alignment: .topLeading) {
                                adBadge
                                    .padding(.top, layout.contentInsets.top)
                                    .padding(.leading, layout.contentInsets.leading)
                            }

                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: max(layout.headlineFontSize + 3, 14))
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.8))
                                .frame(height: layout.callToActionHeight)
                        }
                        .padding(.horizontal, layout.contentInsets.leading)
                        .padding(.vertical, layout.contentInsets.top)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .accessibilityHidden(true)
    }

    private var adBadge: some View {
        Text("광고")
            .font(.system(size: layout.badgeFontSize, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}
