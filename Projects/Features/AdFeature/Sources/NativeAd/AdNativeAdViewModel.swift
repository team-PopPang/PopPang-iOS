import Combine
import Core
import Foundation
import GoogleMobileAds

/// 네이티브 광고 로딩 상태입니다.
public enum AdNativeAdLoadState: Equatable, Sendable {
    /// 아직 광고 요청을 시작하지 않은 상태입니다.
    case idle

    /// 광고를 요청 중인 상태입니다.
    case loading

    /// 광고 로드에 성공한 상태입니다.
    case loaded

    /// 광고 로드에 실패한 상태입니다. 연관 값은 사용자에게 노출하지 않는 디버깅용 메시지입니다.
    case failed(String)
}

/// Google Mobile Ads 네이티브 광고를 로드하고 SwiftUI 뷰에 상태를 공급하는 모델입니다.
///
/// 같은 인스턴스에서 `loadAdIfNeeded()`를 여러 번 호출해도 이미 로드 중이거나 로드된 광고가 있으면 중복 요청하지 않습니다.
@MainActor
public final class AdNativeAdViewModel: NSObject, ObservableObject {
    /// 광고 로딩 상태입니다.
    @Published public private(set) var loadState: AdNativeAdLoadState = .idle

    @Published private(set) var nativeAd: NativeAd?

    /// 렌더링 가능한 광고가 로드되었는지 여부입니다.
    public var hasLoadedAd: Bool {
        nativeAd != nil
    }

    private var adLoader: AdLoader?
    private let adUnitID: String

    /// 네이티브 광고 로더를 생성합니다.
    ///
    /// - Parameter adUnitID: 사용할 AdMob 네이티브 광고 단위 ID입니다. 기본값은 앱 설정의 현재 네이티브 광고 단위 ID입니다.
    public init(adUnitID: String = Constants.AdMob.currentNativeAdUnitId) {
        self.adUnitID = adUnitID
    }

    /// 광고가 아직 없고 로딩 중도 아닐 때만 네이티브 광고 요청을 시작합니다.
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
