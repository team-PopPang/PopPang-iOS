// Legacy copy from HomeFeature before AdFeature split.
// Kept out of compilation while preserving the original implementation for reference.
#if false
import GoogleMobileAds
import SwiftUI
import UIKit

struct HomeNativeAdGridCellView: View {
    @ObservedObject var viewModel: HomeNativeAdViewModel

    var body: some View {
        if let nativeAd = viewModel.nativeAd {
            HomeNativeAdGridCellContainer(nativeAd: nativeAd)
        }
    }
}

private struct HomeNativeAdGridCellContainer: UIViewRepresentable {
    let nativeAd: NativeAd

    func makeUIView(context: Context) -> NativeAdView {
        let nativeAdView = NativeAdView()
        nativeAdView.backgroundColor = .white
        nativeAdView.layer.cornerRadius = 8
        nativeAdView.layer.borderWidth = 1
        nativeAdView.layer.borderColor = UIColor.systemGray5.cgColor
        nativeAdView.clipsToBounds = true

        let mediaView = MediaView()
        mediaView.backgroundColor = .systemGray6
        mediaView.contentMode = .scaleAspectFill
        mediaView.clipsToBounds = true
        mediaView.translatesAutoresizingMaskIntoConstraints = false
        nativeAdView.mediaView = mediaView

        let adBadgeLabel = UILabel()
        adBadgeLabel.text = "광고"
        adBadgeLabel.font = .systemFont(ofSize: 10, weight: .semibold)
        adBadgeLabel.textColor = .white
        adBadgeLabel.textAlignment = .center
        adBadgeLabel.backgroundColor = .systemOrange
        adBadgeLabel.layer.cornerRadius = 3
        adBadgeLabel.clipsToBounds = true
        adBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 18),
            adBadgeLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 18),
        ])

        let headlineLabel = UILabel()
        headlineLabel.font = .systemFont(ofSize: 13, weight: .bold)
        headlineLabel.textColor = .label
        headlineLabel.numberOfLines = 2
        headlineLabel.lineBreakMode = .byTruncatingTail
        nativeAdView.headlineView = headlineLabel

        let callToActionButton = UIButton(type: .system)
        var buttonConfiguration = UIButton.Configuration.filled()
        buttonConfiguration.baseBackgroundColor = .systemOrange
        buttonConfiguration.baseForegroundColor = .white
        buttonConfiguration.cornerStyle = .small
        buttonConfiguration.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 8, bottom: 6, trailing: 8)
        buttonConfiguration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = .systemFont(ofSize: 12, weight: .semibold)
            return attributes
        }
        callToActionButton.configuration = buttonConfiguration
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
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
        contentStack.layoutMargins = UIEdgeInsets(top: 9, left: 8, bottom: 9, right: 8)

        let rootStack = UIStackView(arrangedSubviews: [mediaView, contentStack])
        rootStack.axis = .vertical
        rootStack.alignment = .fill
        rootStack.spacing = 0
        rootStack.translatesAutoresizingMaskIntoConstraints = false

        nativeAdView.addSubview(rootStack)

        NSLayoutConstraint.activate([
            rootStack.topAnchor.constraint(equalTo: nativeAdView.topAnchor),
            rootStack.leadingAnchor.constraint(equalTo: nativeAdView.leadingAnchor),
            rootStack.trailingAnchor.constraint(equalTo: nativeAdView.trailingAnchor),
            rootStack.bottomAnchor.constraint(equalTo: nativeAdView.bottomAnchor),
            mediaView.heightAnchor.constraint(equalToConstant: 204),
            callToActionButton.heightAnchor.constraint(equalToConstant: 31),
        ])

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
#endif
