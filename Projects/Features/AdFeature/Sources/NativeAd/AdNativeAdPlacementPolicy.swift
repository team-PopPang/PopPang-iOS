import Foundation

/// 콘텐츠 개수별 네이티브 광고 삽입 후보 위치를 정의하는 규칙입니다.
///
/// `contentCount`가 `minimumContentCount` 이상이면 `candidateIndexes` 중 하나가 광고 위치 후보가 됩니다.
/// 여러 후보는 광고 여러 개를 뜻하지 않고, 광고 1개를 분산 배치하기 위한 선택지입니다.
public struct AdNativeAdPlacementRule: Hashable, Sendable {
    /// 이 규칙을 적용하기 위한 최소 콘텐츠 개수입니다.
    public let minimumContentCount: Int

    /// 광고를 삽입할 수 있는 0 기반 후보 인덱스 목록입니다.
    public let candidateIndexes: [Int]

    /// 네이티브 광고 배치 규칙을 생성합니다.
    ///
    /// - Parameters:
    ///   - minimumContentCount: 이 규칙을 적용하기 위한 최소 콘텐츠 개수입니다. 음수는 0으로 보정됩니다.
    ///   - candidateIndexes: 광고를 삽입할 수 있는 0 기반 후보 인덱스 목록입니다.
    public init(minimumContentCount: Int, candidateIndexes: [Int]) {
        self.minimumContentCount = max(minimumContentCount, 0)
        self.candidateIndexes = candidateIndexes
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
    /// - 8...11개: index 4
    /// - 12...15개: index 4 또는 6
    /// - 16개 이상: index 4, 6, 8 중 seed 기반 선택
    static let homeGrid = AdNativeAdPlacementConfiguration(
        placementKey: "home-grid-native-ad",
        rules: [
            AdNativeAdPlacementRule(minimumContentCount: 8, candidateIndexes: [4]),
            AdNativeAdPlacementRule(minimumContentCount: 12, candidateIndexes: [4, 6]),
            AdNativeAdPlacementRule(minimumContentCount: 16, candidateIndexes: [4, 6, 8]),
        ]
    )
}

/// 네이티브 광고 삽입 위치를 계산하는 정책입니다.
public enum AdNativeAdPlacementPolicy {
    /// 콘텐츠 개수와 사용자 seed를 기준으로 광고 삽입 인덱스를 계산합니다.
    ///
    /// 같은 `userIdentifier`, 같은 날짜, 같은 `placementKey`에서는 항상 같은 후보 인덱스를 반환합니다.
    /// 날짜가 바뀌거나 사용자/placement가 달라지면 다른 후보가 선택될 수 있습니다.
    ///
    /// - Parameters:
    ///   - contentCount: 광고를 삽입할 콘텐츠 개수입니다.
    ///   - userIdentifier: 사용자별 위치 분산에 사용할 안정적인 식별자입니다.
    ///   - date: 하루 단위 seed를 만들 기준 날짜입니다.
    ///   - configuration: 광고 위치 후보와 seed 설정입니다.
    /// - Returns: 광고 삽입 인덱스입니다. 적용 가능한 규칙이 없으면 `nil`을 반환합니다.
    public static func insertionIndex(
        contentCount: Int,
        userIdentifier: String,
        date: Date = Date(),
        configuration: AdNativeAdPlacementConfiguration = .homeGrid
    ) -> Int? {
        let normalizedContentCount = max(contentCount, 0)
        guard
            let rule = selectedRule(
                contentCount: normalizedContentCount,
                rules: configuration.rules
            )
        else {
            return nil
        }

        let candidates = normalizedCandidateIndexes(
            rule.candidateIndexes,
            contentCount: normalizedContentCount
        )
        guard candidates.isEmpty == false else { return nil }

        let seed = [
            userIdentifier,
            dayKey(for: date, timeZoneIdentifier: configuration.timeZoneIdentifier),
            configuration.placementKey,
        ].joined(separator: "|")
        let hash = stableHash(seed)
        let selectedOffset = Int(hash % UInt64(candidates.count))
        return candidates[selectedOffset]
    }
}

private extension AdNativeAdPlacementPolicy {
    static func selectedRule(
        contentCount: Int,
        rules: [AdNativeAdPlacementRule]
    ) -> AdNativeAdPlacementRule? {
        rules
            .filter { contentCount >= $0.minimumContentCount && $0.candidateIndexes.isEmpty == false }
            .max { $0.minimumContentCount < $1.minimumContentCount }
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

    static func stableHash(_ string: String) -> UInt64 {
        var hash: UInt64 = 14_695_981_039_346_656_037

        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }

        return hash
    }
}
