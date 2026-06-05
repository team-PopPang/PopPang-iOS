import SwiftUI
import AdFeature

/// 광고 ViewModel을 `AdFeatureInterface` 사용자에게 노출하는 타입 별칭입니다.
public typealias AdNativeAdViewModel = AdFeature.AdNativeAdViewModel

/// 광고 로딩 상태를 `AdFeatureInterface` 사용자에게 노출하는 타입 별칭입니다.
public typealias AdNativeAdLoadState = AdFeature.AdNativeAdLoadState

/// 광고 레이아웃 값을 `AdFeatureInterface` 사용자에게 노출하는 타입 별칭입니다.
public typealias AdNativeAdLayout = AdFeature.AdNativeAdLayout

/// 광고 콘텐츠 여백 값을 `AdFeatureInterface` 사용자에게 노출하는 타입 별칭입니다.
public typealias AdNativeAdInsets = AdFeature.AdNativeAdInsets

/// 외부 ViewModel 기반 광고 뷰를 `AdFeatureInterface` 사용자에게 노출하는 타입 별칭입니다.
public typealias AdNativeAdView = AdFeature.AdNativeAdView

/// 자동 로딩 광고 진입 뷰를 `AdFeatureInterface` 사용자에게 노출하는 타입 별칭입니다.
public typealias AdNativeAdEntryView = AdFeature.AdNativeAdEntryView

/// 광고가 삽입된 리스트 아이템 타입을 `AdFeatureInterface` 사용자에게 노출하는 타입 별칭입니다.
public typealias AdInjectedListItem<Item> = AdFeature.AdInjectedListItem<Item>

/// 광고 삽입 리스트 빌더를 `AdFeatureInterface` 사용자에게 노출하는 타입 별칭입니다.
public typealias AdInjectedListItemBuilder = AdFeature.AdInjectedListItemBuilder

/// 광고 피처의 기본 진입 뷰입니다.
public struct AdFeatureEntryView: View {
    public init() {}

    /// 기본 그리드 레이아웃의 자동 로딩 네이티브 광고를 렌더링합니다.
    public var body: some View {
        AdNativeAdEntryView(layout: .grid, reservesSpaceWhileLoading: true)
    }
}
