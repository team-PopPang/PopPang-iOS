import Foundation

public struct RecentSearchStorage: Sendable {
    private let store: Storing
    private let key: String
    private let maximumCount: Int

    public init(
        store: Storing,
        key: String = "recentCategories",
        maximumCount: Int = 5
    ) {
        self.store = store
        self.key = key
        self.maximumCount = maximumCount
    }

    public func load() -> [String] {
        store.value(forKey: key) ?? []
    }

    public func save(_ keywords: [String]) {
        try? store.set(Array(keywords.prefix(maximumCount)), forKey: key)
    }

    public func add(_ keyword: String) {
        var keywords = load()
        keywords.removeAll { $0 == keyword }
        keywords.insert(keyword, at: 0)
        save(keywords)
    }

    public func remove(_ keyword: String) {
        let filteredKeywords = load().filter { $0 != keyword }
        try? store.set(filteredKeywords, forKey: key)
    }

    public func removeAll() {
        store.removeValue(forKey: key)
    }
}
