import SwiftUI
import AdFeature

public typealias AdNativeAdViewModel = AdFeature.AdNativeAdViewModel
public typealias AdNativeAdLoadState = AdFeature.AdNativeAdLoadState
public typealias AdNativeAdLayout = AdFeature.AdNativeAdLayout
public typealias AdNativeAdInsets = AdFeature.AdNativeAdInsets
public typealias AdNativeAdView = AdFeature.AdNativeAdView
public typealias AdNativeAdEntryView = AdFeature.AdNativeAdEntryView
public typealias AdInjectedListItem<Item> = AdFeature.AdInjectedListItem<Item>
public typealias AdInjectedListItemBuilder = AdFeature.AdInjectedListItemBuilder

public struct AdFeatureEntryView: View {
    public init() {}

    public var body: some View {
        AdNativeAdEntryView(layout: .grid, reservesSpaceWhileLoading: true)
    }
}
