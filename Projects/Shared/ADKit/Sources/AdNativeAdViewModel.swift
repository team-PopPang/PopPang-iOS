import Combine
import Core
import Foundation
import GoogleMobileAds

/// 네이티브 광고 로딩 상태입니다.
public enum AdNativeAdLoadState: Equatable, Sendable {
    case idle
    case loading
    case loaded
    case failed(String)
}

/// Google Mobile Ads 네이티브 광고를 로드하고 SwiftUI 뷰에 상태를 공급하는 모델입니다.
@MainActor
public final class AdNativeAdViewModel: NSObject, ObservableObject {
    @Published public private(set) var loadState: AdNativeAdLoadState = .idle
    @Published private(set) var nativeAd: NativeAd?

    public var hasLoadedAd: Bool {
        nativeAd != nil
    }

    private var adLoader: AdLoader?
    private let adUnitID: String

    public init(adUnitID: String = Constants.AdMob.currentNativeAdUnitId) {
        self.adUnitID = adUnitID
    }

    public func loadAdIfNeeded() {
        guard nativeAd == nil, loadState != .loading else { return }
        loadState = .loading

        let mediaOptions = NativeAdMediaAdLoaderOptions()
        mediaOptions.mediaAspectRatio = .landscape

        let adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: nil,
            adTypes: [.native],
            options: [mediaOptions]
        )
        adLoader.delegate = self
        self.adLoader = adLoader
        adLoader.load(Request())
    }
}

extension AdNativeAdViewModel: NativeAdLoaderDelegate, NativeAdDelegate {
    public func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self
        self.nativeAd = nativeAd
        loadState = .loaded
    }

    public func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        nativeAd = nil
        loadState = .failed(error.localizedDescription)
    }
}
