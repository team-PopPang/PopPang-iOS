import Foundation

public enum AdInjectedListItem<Item>: Identifiable {
    case content(Item, id: String)
    case nativeAd(id: String)

    public var id: String {
        switch self {
        case .content(_, let id):
            id
        case .nativeAd(let id):
            id
        }
    }

    public var content: Item? {
        switch self {
        case .content(let item, _):
            item
        case .nativeAd:
            nil
        }
    }
}

public enum AdInjectedListItemBuilder {
    public static func make<Item>(
        items: [Item],
        includesNativeAd: Bool,
        adInsertIndex: Int = 4,
        nativeAdId: String = "native-ad",
        id: (Item) -> String
    ) -> [AdInjectedListItem<Item>] {
        var injectedItems = items.map { item in
            AdInjectedListItem.content(item, id: id(item))
        }
        guard includesNativeAd, injectedItems.isEmpty == false else { return injectedItems }

        let insertIndex = min(max(adInsertIndex, 0), injectedItems.count)
        injectedItems.insert(.nativeAd(id: nativeAdId), at: insertIndex)
        return injectedItems
    }
}
