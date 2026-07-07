# AdFeature

`AdFeature`는 Google Mobile Ads 네이티브 광고를 여러 feature에서 재사용하기 위한 광고 모듈이다.

다른 feature에서는 구현 모듈인 `AdFeature`가 아니라 `AdFeatureInterface`를 import해서 사용한다.

```swift
import AdFeatureInterface
```

## 구성

- `AdNativeAdEntryView`: 자체 ViewModel을 소유하고 등장 시 광고를 자동으로 로드하는 진입 뷰
- `AdNativeAdView`: 외부에서 소유한 `AdNativeAdViewModel`을 렌더링하는 뷰
- `AdNativeAdViewModel`: Google Mobile Ads 네이티브 광고 로딩 상태를 관리하는 모델
- `AdNativeAdSlotStore`: 여러 광고 슬롯의 `AdNativeAdViewModel`을 관리하는 store
- `AdNativeAdLayout`: 광고 내부 배치, 비율, 글자 크기, CTA 버튼 높이를 정의하는 값
- `AdNativeAdPlacementPolicy`: 콘텐츠 개수와 seed 기반으로 광고 삽입 위치를 계산하는 정책
- `AdNativeAdPlacementConfiguration`: placement별 후보 위치와 seed 기준을 조절하는 설정
- `AdInjectedListItemBuilder`: 기존 리스트 중간에 광고 아이템을 삽입하는 헬퍼

## 기본 사용

광고를 단독으로 배치할 때는 `AdNativeAdEntryView`를 사용한다.

```swift
AdNativeAdEntryView(layout: .compactBanner, reservesSpaceWhileLoading: true)
    .frame(height: 112)
```

실제 표시 크기는 호출 지점의 `.frame(...)`, 리스트 셀 크기, 부모 레이아웃 제약으로 결정된다. `AdNativeAdLayout`은 그 안에서 미디어, 제목, 광고 배지, CTA 버튼을 어떻게 배치할지만 정의한다.

## 그리드 셀 사용

홈 2열 그리드처럼 셀 크기가 정해진 곳에서는 `.grid` 레이아웃을 사용한다.

```swift
AdNativeAdEntryView(layout: .grid, reservesSpaceWhileLoading: true)
    .frame(width: 170, height: 302)
```

광고 로드 전에도 레이아웃 공간을 유지해야 하면 `reservesSpaceWhileLoading`을 `true`로 둔다. 광고가 없을 때 공간 자체를 없애고 싶으면 `false`를 사용한다.

## 외부 ViewModel 사용

리스트에 광고가 로드된 뒤에만 광고 셀을 삽입해야 하는 경우, 화면이 `AdNativeAdViewModel`을 직접 소유한다.

```swift
@StateObject private var nativeAdViewModel = AdNativeAdViewModel()

var body: some View {
    AdNativeAdView(
        viewModel: nativeAdViewModel,
        layout: .grid
    )
    .task {
        nativeAdViewModel.loadAdIfNeeded()
    }
}
```

`loadAdIfNeeded()`는 이미 로드 중이거나 로드된 광고가 있으면 중복 요청하지 않는다.

## 리스트 중간 삽입

기존 콘텐츠 배열 중간에 광고 셀을 넣을 때는 `AdNativeAdSlotStore`와 `AdInjectedListItemBuilder`를 함께 사용한다.

```swift
@StateObject private var nativeAdSlotStore = AdNativeAdSlotStore()

let placements = AdNativeAdPlacementPolicy.placements(
    contentCount: popups.count,
    userIdentifier: userUuid,
    adCount: 2,
    configuration: .homeGrid
)
let loadedSlotIDs = nativeAdSlotStore.loadedSlotIDs(in: placements.map(\.id))

let items = AdInjectedListItemBuilder.make(
    items: popups,
    nativeAdPlacements: placements.filter { loadedSlotIDs.contains($0.id) },
    id: { $0.popupUuid }
)

for item in items {
    switch item {
    case .content(let popup, _):
        PopupCell(popup: popup)

    case .nativeAd(let slotID):
        AdNativeAdView(
            viewModel: nativeAdSlotStore.viewModel(for: slotID),
            layout: .grid
        )
    }
}
```

```swift
.task(id: placements.map(\.id)) {
    nativeAdSlotStore.loadAdIfNeeded(for: placements.map(\.id))
}
```

같은 네이티브 광고 객체를 여러 셀에 재사용하지 않는다. 광고가 여러 개 필요하면 슬롯마다 별도 `AdNativeAdViewModel`을 사용한다.

## 배치 정책

기본 홈 grid 정책은 `Seeded Row-Aligned Jitter` 방식이다.
슬롯 하나의 후보 index 여러 개는 광고 여러 개를 넣는다는 뜻이 아니라, 해당 슬롯의 광고 1개를 어느 위치에 넣을지 고르는 선택지다.

```text
8개 미만     -> 광고 없음
8...19개    -> 광고 1개
20...31개   -> 광고 2개
32개 이상   -> 광고 3개
```

선택은 `userIdentifier + yyyyMMdd + placementKey + slotID`로 만든 seed를 stable hash해서 결정한다. 같은 유저, 같은 날짜, 같은 placement, 같은 슬롯에서는 앱을 다시 열어도 같은 위치가 나온다. 날짜가 바뀌거나 사용자/placement가 달라지면 다른 후보가 선택될 수 있다.

```swift
let placements = AdNativeAdPlacementPolicy.placements(
    contentCount: gridPopups.count,
    userIdentifier: userUuid,
    adCount: 2,
    configuration: .homeGrid
)
```

`adCount`는 실제로 사용할 광고 개수다. `nil`이면 선택된 규칙의 슬롯 개수를 모두 사용하고, `0`이면 광고를 넣지 않는다. 요청한 개수가 설정된 슬롯보다 많으면 설정된 슬롯 개수까지만 반환한다.

Swift 기본 `hashValue`는 앱 실행마다 달라질 수 있으므로 사용하지 않는다. `AdNativeAdPlacementPolicy`는 내부에서 FNV-1a 기반 stable hash를 사용한다.

## 배치 설정 조절

placement별로 최소 콘텐츠 수와 후보 위치를 바꾸고 싶으면 `AdNativeAdPlacementConfiguration`을 직접 만든다.

```swift
let relaxedHomeGrid = AdNativeAdPlacementConfiguration(
    placementKey: "home-grid-native-ad-v2",
    rules: [
        AdNativeAdPlacementRule(
            minimumContentCount: 8,
            slots: [
                AdNativeAdPlacementSlot(id: "native-ad-1", candidateIndexes: [4, 6]),
            ]
        ),
        AdNativeAdPlacementRule(
            minimumContentCount: 20,
            slots: [
                AdNativeAdPlacementSlot(id: "native-ad-1", candidateIndexes: [4, 6]),
                AdNativeAdPlacementSlot(id: "native-ad-2", candidateIndexes: [14, 16]),
            ]
        ),
    ]
)
```

규칙은 조건을 만족하는 것 중 `minimumContentCount`가 가장 큰 규칙이 사용된다. 후보 index가 콘텐츠 개수보다 크면 마지막 위치로 보정되고, 음수면 0으로 보정된다.

## 커스텀 레이아웃

기본 프리셋으로는 `.grid`, `.compactBanner`를 제공한다. 화면별로 다른 비율이나 글자 크기가 필요하면 `AdNativeAdLayout`을 직접 만든다.

```swift
let detailBanner = AdNativeAdLayout(
    axis: .horizontal,
    mediaAspectRatio: 1,
    horizontalMediaWidthRatio: 0.4,
    cornerRadius: 8,
    borderWidth: 1,
    contentInsets: AdNativeAdInsets(top: 12, leading: 12, bottom: 12, trailing: 12),
    headlineFontSize: 15,
    badgeFontSize: 10,
    callToActionFontSize: 12,
    callToActionHeight: 32
)
```

`mediaAspectRatio`는 최소 `0.1`로 보정되고, `horizontalMediaWidthRatio`는 `0.2...0.6` 범위로 보정된다.

## 설정

앱 타깃은 Info.plist에 다음 값을 제공해야 한다.

- `GADApplicationIdentifier`
- `ADMOB_NATIVE_AD_UNIT_ID`

`Core.Constants.AdMob.currentNativeAdUnitId`는 Debug에서 Google 공식 테스트 네이티브 광고 단위 ID를 사용하고, Release에서 앱 설정의 `ADMOB_NATIVE_AD_UNIT_ID`를 사용한다.

`AdFeatureDemo`는 단독 실행을 위해 Google 공식 테스트 App ID를 Info.plist에 포함한다.
