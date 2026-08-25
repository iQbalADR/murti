import Foundation

/// Persistent byte store for the disk cache (Strategy).
public protocol MurtiCacheStore: Sendable {
    func data(for key: String) async -> Data?
    func store(_ data: Data, for key: String) async
    func remove(_ key: String) async
}

/// In-memory store — the default for tests and previews (not persisted).
public actor MemoryCacheStore: MurtiCacheStore {
    private var storage: [String: Data] = [:]
    public init() {}
    public func data(for key: String) -> Data? { storage[key] }
    public func store(_ data: Data, for key: String) { storage[key] = data }
    public func remove(_ key: String) { storage[key] = nil }
}
