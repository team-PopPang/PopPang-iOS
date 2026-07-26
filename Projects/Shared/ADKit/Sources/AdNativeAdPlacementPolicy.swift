import Foundation

public struct AdNativeAdPlacementSlot: Hashable, Identifiable, Sendable {
    public let id: String
    public let candidateIndexes: [Int]

    public init(id: String, candidateIndexes: [Int]) {
        self.id = id
        self.candidateIndexes = candidateIndexes
    }
}

public struct AdNativeAdPlacementRule: Hashable, Sendable {
    public let minimumContentCount: Int
    public let slots: [AdNativeAdPlacementSlot]

    public var candidateIndexes: [Int] {
        slots.first?.candidateIndexes ?? []
    }

    public init(minimumContentCount: Int, candidateIndexes: [Int]) {
        self.minimumContentCount = max(minimumContentCount, 0)
        self.slots = [
            AdNativeAdPlacementSlot(id: "native-ad-1", candidateIndexes: candidateIndexes),
        ]
    }

    public init(minimumContentCount: Int, slots: [AdNativeAdPlacementSlot]) {
        self.minimumContentCount = max(minimumContentCount, 0)
        self.slots = slots
    }
}

public struct AdNativeAdPlacement: Hashable, Identifiable, Sendable {
    public let id: String
    public let insertIndex: Int

    public init(id: String, insertIndex: Int) {
        self.id = id
        self.insertIndex = insertIndex
    }
}

public struct AdNativeAdPlacementConfiguration: Hashable, Sendable {
    public let placementKey: String
    public let rules: [AdNativeAdPlacementRule]
    public let timeZoneIdentifier: String

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

    /// Home grid pagination uses the same first three rules as `homeGrid` and
    /// keeps adding slots with the same cadence as more content is appended.
    static func paginatedHomeGrid(contentCount: Int) -> Self {
        let normalizedContentCount = max(contentCount, 0)
        let firstSlotMinimumContentCount = 8
        let contentCountPerAdditionalSlot = 12

        guard normalizedContentCount >= firstSlotMinimumContentCount else {
            return .init(
                placementKey: "home-grid-native-ad",
                rules: []
            )
        }

        let slotCount =
            (normalizedContentCount - firstSlotMinimumContentCount)
            / contentCountPerAdditionalSlot
            + 1

        let slots = (0..<slotCount).map { slotOffset in
            AdNativeAdPlacementSlot(
                id: "native-ad-\(slotOffset + 1)",
                candidateIndexes: [
                    4 + (10 * slotOffset),
                    6 + (10 * slotOffset),
                ]
            )
        }

        return .init(
            placementKey: "home-grid-native-ad",
            rules: [
                AdNativeAdPlacementRule(
                    minimumContentCount: 0,
                    slots: slots
                ),
            ]
        )
    }
}

public enum AdNativeAdPlacementPolicy {
    /// Returns a pagination-safe Home grid schedule.
    ///
    /// The first three slots match `homeGrid` exactly. Additional slots keep
    /// the same 12-content threshold and 10-index placement cadence.
    public static func paginatedHomeGridPlacements(
        contentCount: Int,
        userIdentifier: String,
        adCount: Int? = nil,
        date: Date = Date()
    ) -> [AdNativeAdPlacement] {
        placements(
            contentCount: contentCount,
            userIdentifier: userIdentifier,
            adCount: adCount,
            date: date,
            configuration: .paginatedHomeGrid(contentCount: contentCount)
        )
    }

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

    static func stableHash(_ string: String) -> UInt64 {
        let prime: UInt64 = 1_099_511_628_211
        var hash: UInt64 = 14_695_981_039_346_656_037

        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash &*= prime
        }

        return hash
    }
}
