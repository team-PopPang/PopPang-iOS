import Domain

enum HomeGridItem: Identifiable {
    case popup(Popup)
    case nativeAd

    var id: String {
        switch self {
        case let .popup(popup):
            popup.popupUuid
        case .nativeAd:
            "home-native-ad"
        }
    }
}

enum HomeNativeAdGridItemBuilder {
    static func make(
        popups: [Popup],
        includesNativeAd: Bool,
        adInsertIndex: Int = 4
    ) -> [HomeGridItem] {
        var items = popups.map(HomeGridItem.popup)
        guard includesNativeAd, items.isEmpty == false else { return items }

        let insertIndex = min(adInsertIndex, items.count)
        items.insert(.nativeAd, at: insertIndex)
        return items
    }
}
