// Legacy copy from HomeFeature before AdFeature split.
// Kept out of compilation while preserving the original implementation for reference.
#if false
import Core
import Foundation
import GoogleMobileAds

@MainActor
final class HomeNativeAdViewModel: NSObject, ObservableObject {
    @Published private(set) var nativeAd: NativeAd?
    @Published private(set) var errorMessage: String?

    private var adLoader: AdLoader?
    private var isLoading = false
    private let adUnitID: String

    init(adUnitID: String = Constants.AdMob.currentNativeAdUnitId) {
        self.adUnitID = adUnitID
    }

    func loadAdIfNeeded() {
        guard nativeAd == nil, isLoading == false else { return }
        isLoading = true
        errorMessage = nil

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

extension HomeNativeAdViewModel: NativeAdLoaderDelegate, NativeAdDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        nativeAd.delegate = self
        self.nativeAd = nativeAd
        isLoading = false
        errorMessage = nil
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
    }
}
#endif
