import Foundation

/// 콘텐츠 리스트 중간에 네이티브 광고 셀을 삽입하기 위한 공통 아이템 타입입니다.
///
/// `HomeFeature`처럼 기존 도메인 모델 배열을 그대로 순회하되, 특정 위치에 광고 행을 끼워 넣어야 할 때 사용합니다.
public enum AdInjectedListItem<Item>: Identifiable {
    /// 기존 화면이 렌더링하던 일반 콘텐츠입니다.
    case content(Item, id: String)

    /// Google Mobile Ads 네이티브 광고가 렌더링될 자리입니다.
    case nativeAd(id: String)

    /// diffable/list 기반 UI에서 사용할 안정적인 식별자입니다.
    public var id: String {
        switch self {
        case .content(_, let id):
            id
        case .nativeAd(let id):
            id
        }
    }

    /// 일반 콘텐츠인 경우에만 원본 아이템을 반환합니다.
    public var content: Item? {
        switch self {
        case .content(let item, _):
            item
        case .nativeAd:
            nil
        }
    }
}

/// 기존 콘텐츠 배열에 네이티브 광고 아이템을 삽입하는 유틸리티입니다.
public enum AdInjectedListItemBuilder {
    /// 광고 로드 여부와 삽입 위치를 기준으로 리스트 아이템 배열을 생성합니다.
    ///
    /// - Parameters:
    ///   - items: 광고가 삽입될 원본 콘텐츠 배열입니다.
    ///   - includesNativeAd: `true`이면 원본 배열이 비어 있지 않을 때 광고 아이템을 삽입합니다.
    ///   - adInsertIndex: 광고를 삽입할 0 기반 인덱스입니다. 배열 범위를 벗어나면 가능한 범위로 보정됩니다.
    ///   - nativeAdId: 광고 아이템의 식별자입니다. 같은 리스트 안에서 고유해야 합니다.
    ///   - id: 원본 콘텐츠에서 안정적인 식별자를 추출하는 클로저입니다.
    /// - Returns: 일반 콘텐츠와 네이티브 광고 자리가 섞인 리스트 아이템 배열입니다.
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
