import Core
import GoogleMobileAds
import SwiftUI
import UIKit

public struct AdNativeAdEntryView: View {
    @StateObject private var viewModel: AdNativeAdViewModel

    private let layout: AdNativeAdLayout
    private let reservesSpaceWhileLoading: Bool

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

public struct AdNativeAdView: View {
    @ObservedObject private var viewModel: AdNativeAdViewModel

    private let layout: AdNativeAdLayout
    private let reservesSpaceWhileLoading: Bool

    public init(
        viewModel: AdNativeAdViewModel,
        layout: AdNativeAdLayout = .grid,
        reservesSpaceWhileLoading: Bool = false
    ) {
        self.viewModel = viewModel
        self.layout = layout
        self.reservesSpaceWhileLoading = reservesSpaceWhileLoading
    }

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
