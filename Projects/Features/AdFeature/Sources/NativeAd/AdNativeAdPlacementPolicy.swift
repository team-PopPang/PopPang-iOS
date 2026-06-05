import Foundation

/// 하나의 네이티브 광고 슬롯이 삽입될 후보 위치를 정의하는 값입니다.
///
/// 여러 후보는 광고 여러 개를 뜻하지 않고, 이 슬롯의 광고 1개를 분산 배치하기 위한 선택지입니다.
public struct AdNativeAdPlacementSlot: Hashable, Identifiable, Sendable {
    /// 슬롯 식별자입니다. 같은 placement 안에서 고유해야 합니다.
    public let id: String

    /// 광고를 삽입할 수 있는 0 기반 후보 인덱스 목록입니다.
    public let candidateIndexes: [Int]

    /// 네이티브 광고 슬롯 후보를 생성합니다.
    ///
    /// - Parameters:
    ///   - id: 슬롯 식별자입니다. 같은 placement 안에서 고유해야 합니다.
    ///   - candidateIndexes: 광고를 삽입할 수 있는 0 기반 후보 인덱스 목록입니다.
    public init(id: String, candidateIndexes: [Int]) {
        self.id = id
        self.candidateIndexes = candidateIndexes
    }
}

/// 콘텐츠 개수별 네이티브 광고 삽입 슬롯 규칙입니다.
///
/// `contentCount`가 `minimumContentCount` 이상이면 `slots`의 각 슬롯에서 광고 위치를 하나씩 선택합니다.
public struct AdNativeAdPlacementRule: Hashable, Sendable {
    /// 이 규칙을 적용하기 위한 최소 콘텐츠 개수입니다.
    public let minimumContentCount: Int

    /// 이 규칙에서 활성화할 광고 슬롯 목록입니다.
    public let slots: [AdNativeAdPlacementSlot]

    /// 첫 번째 슬롯의 후보 인덱스 목록입니다.
    ///
    /// 단일 광고만 쓰는 기존 호출부와 문서 호환을 위한 편의 프로퍼티입니다.
    public var candidateIndexes: [Int] {
        slots.first?.candidateIndexes ?? []
    }

    /// 네이티브 광고 배치 규칙을 생성합니다.
    ///
    /// 이 생성자는 광고 1개만 필요한 화면에 사용합니다. 여러 광고 슬롯이 필요하면 `init(minimumContentCount:slots:)`를 사용합니다.
    ///
    /// - Parameters:
    ///   - minimumContentCount: 이 규칙을 적용하기 위한 최소 콘텐츠 개수입니다. 음수는 0으로 보정됩니다.
    ///   - candidateIndexes: 첫 번째 광고 슬롯을 삽입할 수 있는 0 기반 후보 인덱스 목록입니다.
    public init(minimumContentCount: Int, candidateIndexes: [Int]) {
        self.minimumContentCount = max(minimumContentCount, 0)
        self.slots = [
            AdNativeAdPlacementSlot(id: "native-ad-1", candidateIndexes: candidateIndexes),
        ]
    }

    /// 여러 네이티브 광고 슬롯을 포함하는 배치 규칙을 생성합니다.
    ///
    /// - Parameters:
    ///   - minimumContentCount: 이 규칙을 적용하기 위한 최소 콘텐츠 개수입니다. 음수는 0으로 보정됩니다.
    ///   - slots: 이 규칙에서 활성화할 광고 슬롯 목록입니다.
    public init(minimumContentCount: Int, slots: [AdNativeAdPlacementSlot]) {
        self.minimumContentCount = max(minimumContentCount, 0)
        self.slots = slots
    }
}

/// 계산된 네이티브 광고 삽입 위치입니다.
public struct AdNativeAdPlacement: Hashable, Identifiable, Sendable {
    /// 리스트에서 광고 슬롯을 식별할 id입니다.
    public let id: String

    /// 원본 콘텐츠 배열 기준 0 기반 삽입 인덱스입니다.
    public let insertIndex: Int

    /// 계산된 네이티브 광고 삽입 위치를 생성합니다.
    ///
    /// - Parameters:
    ///   - id: 리스트에서 광고 슬롯을 식별할 id입니다.
    ///   - insertIndex: 원본 콘텐츠 배열 기준 0 기반 삽입 인덱스입니다.
    public init(id: String, insertIndex: Int) {
        self.id = id
        self.insertIndex = insertIndex
    }
}

/// 네이티브 광고 삽입 위치를 계산하기 위한 설정입니다.
public struct AdNativeAdPlacementConfiguration: Hashable, Sendable {
    /// seed를 구분하기 위한 광고 위치 키입니다.
    public let placementKey: String

    /// 콘텐츠 개수별 후보 위치 규칙입니다.
    public let rules: [AdNativeAdPlacementRule]

    /// 하루 단위 seed를 만들 때 사용할 타임존 식별자입니다.
    public let timeZoneIdentifier: String

    /// 네이티브 광고 배치 설정을 생성합니다.
    ///
    /// - Parameters:
    ///   - placementKey: seed를 구분하기 위한 광고 위치 키입니다.
    ///   - rules: 콘텐츠 개수별 후보 위치 규칙입니다. 조건을 만족하는 규칙 중 `minimumContentCount`가 가장 큰 규칙이 사용됩니다.
    ///   - timeZoneIdentifier: 하루 단위 seed를 만들 때 사용할 타임존 식별자입니다.
    public init(
        placementKey: String,
        rules: [AdNativeAdPlacementRule],
        timeZoneIdentifier: String = TimeZone.current.identifier
    ) {
        self.placementKey = placementKey
        self.rules = rules
        self.timeZoneIdentifier = timeZoneIdentifier
    }
}

public extension AdNativeAdPlacementConfiguration {
    /// PopPang 홈 2열 grid에 맞춘 기본 배치 설정입니다.
    ///
    /// - 8개 미만: 광고 없음
    /// - 8...19개: 광고 1개
    /// - 20...31개: 광고 2개
    /// - 32개 이상: 광고 3개
    static let homeGrid = AdNativeAdPlacementConfiguration(
        placementKey: "home-grid-native-ad",
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
            AdNativeAdPlacementRule(
                minimumContentCount: 32,
                slots: [
                    AdNativeAdPlacementSlot(id: "native-ad-1", candidateIndexes: [4, 6]),
                    AdNativeAdPlacementSlot(id: "native-ad-2", candidateIndexes: [14, 16]),
                    AdNativeAdPlacementSlot(id: "native-ad-3", candidateIndexes: [24, 26]),
                ]
            ),
        ]
    )
}

/// 네이티브 광고 삽입 위치를 계산하는 정책입니다.
public enum AdNativeAdPlacementPolicy {
    /// 콘텐츠 개수와 사용자 seed를 기준으로 광고 삽입 위치 목록을 계산합니다.
    ///
    /// 같은 `userIdentifier`, 같은 날짜, 같은 `placementKey`, 같은 슬롯에서는 항상 같은 후보 인덱스를 반환합니다.
    /// 날짜가 바뀌거나 사용자/placement가 달라지면 다른 후보가 선택될 수 있습니다.
    ///
    /// - Parameters:
    ///   - contentCount: 광고를 삽입할 콘텐츠 개수입니다.
    ///   - userIdentifier: 사용자별 위치 분산에 사용할 안정적인 식별자입니다.
    ///   - adCount: 실제로 사용할 광고 개수입니다. `nil`이면 선택된 규칙의 슬롯 개수를 모두 사용합니다.
    ///   - date: 하루 단위 seed를 만들 기준 날짜입니다.
    ///   - configuration: 광고 위치 후보와 seed 설정입니다.
    /// - Returns: 광고 삽입 위치 목록입니다. 적용 가능한 규칙이 없으면 빈 배열을 반환합니다.
    public static func placements(
        contentCount: Int,
        userIdentifier: String,
        adCount: Int? = nil,
        date: Date = Date(),
        configuration: AdNativeAdPlacementConfiguration = .homeGrid
    ) -> [AdNativeAdPlacement] {
        let normalizedContentCount = max(contentCount, 0)
        guard
            let rule = selectedRule(
                contentCount: normalizedContentCount,
                rules: configuration.rules
            )
        else {
            return []
        }

        var placements: [AdNativeAdPlacement] = []
        var usedIDs: Set<String> = []
        let day = dayKey(for: date, timeZoneIdentifier: configuration.timeZoneIdentifier)

        for slot in limitedSlots(rule.slots, adCount: adCount) where usedIDs.contains(slot.id) == false {
            let candidates = normalizedCandidateIndexes(
                slot.candidateIndexes,
                contentCount: normalizedContentCount
            )
            guard candidates.isEmpty == false else { continue }

            let seed = [
                userIdentifier,
                day,
                configuration.placementKey,
                slot.id,
            ].joined(separator: "|")
            let hash = stableHash(seed)
            let selectedOffset = Int(hash % UInt64(candidates.count))
            placements.append(AdNativeAdPlacement(id: slot.id, insertIndex: candidates[selectedOffset]))
            usedIDs.insert(slot.id)
        }

        return placements.sorted { lhs, rhs in
            if lhs.insertIndex == rhs.insertIndex {
                return lhs.id < rhs.id
            }
            return lhs.insertIndex < rhs.insertIndex
        }
    }

    /// 콘텐츠 개수와 사용자 seed를 기준으로 광고 삽입 인덱스 목록을 계산합니다.
    ///
    /// 슬롯 id가 필요 없는 호출부에서만 사용합니다.
    ///
    /// - Parameters:
    ///   - contentCount: 광고를 삽입할 콘텐츠 개수입니다.
    ///   - userIdentifier: 사용자별 위치 분산에 사용할 안정적인 식별자입니다.
    ///   - adCount: 실제로 사용할 광고 개수입니다. `nil`이면 선택된 규칙의 슬롯 개수를 모두 사용합니다.
    ///   - date: 하루 단위 seed를 만들 기준 날짜입니다.
    ///   - configuration: 광고 위치 후보와 seed 설정입니다.
    /// - Returns: 광고 삽입 인덱스 목록입니다. 적용 가능한 규칙이 없으면 빈 배열을 반환합니다.
    public static func insertionIndexes(
        contentCount: Int,
        userIdentifier: String,
        adCount: Int? = nil,
        date: Date = Date(),
        configuration: AdNativeAdPlacementConfiguration = .homeGrid
    ) -> [Int] {
        placements(
            contentCount: contentCount,
            userIdentifier: userIdentifier,
            adCount: adCount,
            date: date,
            configuration: configuration
        )
        .map(\.insertIndex)
    }

    /// 콘텐츠 개수와 사용자 seed를 기준으로 광고 삽입 인덱스를 계산합니다.
    ///
    /// 같은 `userIdentifier`, 같은 날짜, 같은 `placementKey`에서는 항상 같은 후보 인덱스를 반환합니다.
    /// 날짜가 바뀌거나 사용자/placement가 달라지면 다른 후보가 선택될 수 있습니다.
    ///
    /// - Parameters:
    ///   - contentCount: 광고를 삽입할 콘텐츠 개수입니다.
    ///   - userIdentifier: 사용자별 위치 분산에 사용할 안정적인 식별자입니다.
    ///   - adCount: 실제로 사용할 광고 개수입니다. 첫 번째 광고 위치만 반환하므로 기본적으로 `1`을 사용합니다.
    ///   - date: 하루 단위 seed를 만들 기준 날짜입니다.
    ///   - configuration: 광고 위치 후보와 seed 설정입니다.
    /// - Returns: 광고 삽입 인덱스입니다. 적용 가능한 규칙이 없으면 `nil`을 반환합니다.
    public static func insertionIndex(
        contentCount: Int,
        userIdentifier: String,
        adCount: Int = 1,
        date: Date = Date(),
        configuration: AdNativeAdPlacementConfiguration = .homeGrid
    ) -> Int? {
        placements(
            contentCount: contentCount,
            userIdentifier: userIdentifier,
            adCount: adCount,
            date: date,
            configuration: configuration
        )
        .first?
        .insertIndex
    }
}

private extension AdNativeAdPlacementPolicy {
    static func selectedRule(
        contentCount: Int,
        rules: [AdNativeAdPlacementRule]
    ) -> AdNativeAdPlacementRule? {
        rules
            .filter { contentCount >= $0.minimumContentCount && $0.slots.isEmpty == false }
            .max { $0.minimumContentCount < $1.minimumContentCount }
    }

    static func limitedSlots(
        _ slots: [AdNativeAdPlacementSlot],
        adCount: Int?
    ) -> [AdNativeAdPlacementSlot] {
        var uniqueSlots: [AdNativeAdPlacementSlot] = []
        var usedIDs: Set<String> = []

        for slot in slots where usedIDs.contains(slot.id) == false {
            uniqueSlots.append(slot)
            usedIDs.insert(slot.id)
        }

        guard let adCount else { return uniqueSlots }
        return Array(uniqueSlots.prefix(max(adCount, 0)))
    }

    static func normalizedCandidateIndexes(
        _ candidateIndexes: [Int],
        contentCount: Int
    ) -> [Int] {
        var normalizedIndexes: [Int] = []

        for candidateIndex in candidateIndexes {
            let normalizedIndex = min(max(candidateIndex, 0), contentCount)
            if normalizedIndexes.contains(normalizedIndex) == false {
                normalizedIndexes.append(normalizedIndex)
            }
        }

        return normalizedIndexes
    }

    static func dayKey(for date: Date, timeZoneIdentifier: String) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? .current
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        return String(
            format: "%04d%02d%02d",
            components.year ?? 0,
            components.month ?? 0,
            components.day ?? 0
        )
    }

    /// FNV-1a 해시 알고리즘을 사용하여 문자열의 결정적 해시값을 계산합니다.
    static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037

        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }

        return hash
    }
}
