import Core
import GoogleMobileAds
import SwiftUI
import UIKit

/// 자체 `AdNativeAdViewModel`을 소유하고 등장 시 네이티브 광고를 자동으로 로드하는 진입 뷰입니다.
///
/// 호출 화면은 이 뷰에 `.frame(...)`을 적용해서 실제 표시 크기를 결정할 수 있습니다.
public struct AdNativeAdEntryView: View {
    @StateObject private var viewModel: AdNativeAdViewModel

    private let layout: AdNativeAdLayout
    private let reservesSpaceWhileLoading: Bool

    /// 자동 로딩 네이티브 광고 뷰를 생성합니다.
    ///
    /// - Parameters:
    ///   - adUnitID: 사용할 AdMob 네이티브 광고 단위 ID입니다. `nil`이면 앱 설정의 현재 네이티브 광고 단위 ID를 사용합니다.
    ///   - layout: 광고 내부 배치와 글자 크기를 정의하는 레이아웃입니다.
    ///   - reservesSpaceWhileLoading: `true`이면 광고가 로드되기 전에도 투명 뷰로 부모가 잡아둔 공간을 유지합니다.
    public init(
        adUnitID: String? = nil,
        layout: AdNativeAdLayout = .grid,
        reservesSpaceWhileLoading: Bool = false
    ) {
        _viewModel = StateObject(
            wrappedValue: AdNativeAdViewModel(adUnitID: adUnitID ?? Constants.AdMob.currentNativeAdUnitId)
        )
        self.layout = layout
        self.reservesSpaceWhileLoading = reservesSpaceWhileLoading
    }

    /// 광고 로딩 상태에 따라 네이티브 광고 또는 투명 placeholder를 렌더링합니다.
    public var body: some View {
        AdNativeAdView(
            viewModel: viewModel,
            layout: layout,
            reservesSpaceWhileLoading: reservesSpaceWhileLoading
        )
        .task {
            viewModel.loadAdIfNeeded()
        }
    }
}

/// 외부에서 소유한 `AdNativeAdViewModel`을 렌더링하는 네이티브 광고 뷰입니다.
///
/// 하나의 화면에서 광고 로드 시점과 리스트 삽입 여부를 직접 제어해야 할 때 사용합니다.
public struct AdNativeAdView: View {
    @ObservedObject private var viewModel: AdNativeAdViewModel

    private let layout: AdNativeAdLayout
    private let reservesSpaceWhileLoading: Bool

    /// 외부 ViewModel 기반 네이티브 광고 뷰를 생성합니다.
    ///
    /// - Parameters:
    ///   - viewModel: 광고 로딩과 상태를 소유하는 모델입니다.
    ///   - layout: 광고 내부 배치와 글자 크기를 정의하는 레이아웃입니다.
    ///   - reservesSpaceWhileLoading: `true`이면 광고가 로드되기 전에도 투명 뷰로 부모가 잡아둔 공간을 유지합니다.
    public init(
        viewModel: AdNativeAdViewModel,
        layout: AdNativeAdLayout = .grid,
        reservesSpaceWhileLoading: Bool = false
    ) {
        self.viewModel = viewModel
        self.layout = layout
        self.reservesSpaceWhileLoading = reservesSpaceWhileLoading
    }

    /// 로드된 광고가 있으면 Google Mobile Ads 네이티브 광고 뷰를 렌더링합니다.
    public var body: some View {
        if let nativeAd = viewModel.nativeAd {
            AdNativeAdContainer(nativeAd: nativeAd, layout: layout)
        } else if reservesSpaceWhileLoading {
            Color.clear
        }
    }
}

private struct AdNativeAdContainer: UIViewRepresentable {
    let nativeAd: NativeAd
    let layout: AdNativeAdLayout

    func makeUIView(context: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()
        nativeAdView.backgroundColor = .white
        nativeAdView.layer.cornerRadius = layout.cornerRadius
        nativeAdView.layer.borderWidth = layout.borderWidth
        nativeAdView.layer.borderColor = UIColor.systemGray5.cgColor
        nativeAdView.clipsToBounds = true

        let mediaView = makeMediaView()
        nativeAdView.mediaView = mediaView

        let adBadgeLabel = makeBadgeLabel()
        let headlineLabel = makeHeadlineLabel()
        nativeAdView.headlineView = headlineLabel

        let callToActionButton = makeCallToActionButton()
        nativeAdView.callToActionView = callToActionButton

        let titleStack = UIStackView(arrangedSubviews: [adBadgeLabel, headlineLabel])
        titleStack.axis = .horizontal
        titleStack.alignment = .top
        titleStack.spacing = 6

        let contentStack = UIStackView(arrangedSubviews: [titleStack, callToActionButton])
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = 8
        contentStack.isLayoutMarginsRelativeArrangement = true
        contentStack.layoutMargins = UIEdgeInsets(
            top: layout.contentInsets.top,
            left: layout.contentInsets.leading,
            bottom: layout.contentInsets.bottom,
            right: layout.contentInsets.trailing
        )

        let rootStack = UIStackView(arrangedSubviews: [mediaView, contentStack])
        rootStack.axis = layout.axis == .vertical ? .vertical : .horizontal
        rootStack.alignment = .fill
        rootStack.spacing = 0
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        nativeAdView.addSubview(rootStack)

        var constraints: [NSLayoutConstraint] = [
            rootStack.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            rootStack.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor),
            callToActionButton.heightAnchor.constraint(equalToConstant: layout.callToActionHeight),
        ]

        switch layout.axis {
        case .vertical:
            constraints.append(
                mediaView.heightAnchor.constraint(
                    equalTo: mediaView.widthAnchor,
                    multiplier: 1 / layout.mediaAspectRatio
                )
            )
        case .horizontal:
            constraints.append(
                mediaView.widthAnchor.constraint(
                    equalTo: nativeAdView.widthAnchor,
                    multiplier: layout.horizontalMediaWidthRatio
                )
            )
        }

        NSLayoutConstraint.activate(constraints)

        return nativeAdView
    }

    func updateUIView(_ nativeAdView: NativeAdView, context: Context) {
        (nativeAdView.headlineView as? UILabel)?.text = nativeAd.headline
        nativeAdView.mediaView?.mediaContent = nativeAd.mediaContent

        if let button = nativeAdView.callToActionView as? UIButton {
            var configuration = button.configuration
            configuration?.title = nativeAd.callToAction
            button.configuration = configuration
        }
        nativeAdView.callToActionView?.isHidden = nativeAd.callToAction == nil
        nativeAdView.callToActionView?.isUserInteractionEnabled = false

        nativeAdView.nativeAd = nativeAd
    }
}

private extension AdNativeAdContainer {
    func makeMediaView() -> MediaView {
        let mediaView = MediaView()
        mediaView.backgroundColor = .systemGray6
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        return mediaView
    }

    func makeBadgeLabel() -> UILabel {
        let label = UILabel()
        label.text = "광고"
        label.font = .systemFont(ofSize: layout.badgeFontSize, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = .systemOrange
        label.layer.cornerRadius = 3
        label.clipsToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            label.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ])

        return label
    }

    func makeHeadlineLabel() -> UILabel {
        let label = UILabel()
        label.font = .systemFont(ofSize: layout.headlineFontSize, weight: .bold)
        label.textColor = .label
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }

    func makeCallToActionButton() -> UIButton {
        let button = UIButton(type: .system)
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = .systemOrange
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .small
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: layout.callToActionFontSize, weight: .semibold)
            return attributes
        }
        button.configuration = configuration
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }
}
