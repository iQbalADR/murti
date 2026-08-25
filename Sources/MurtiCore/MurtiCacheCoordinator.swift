import Foundation

/// Holds the cache's mutable session state (render cache, manifest, last-good
/// versions) so `MurtiEngine` stays a value type. Main-actor: it is read/written
/// during `load` on the main actor.
@MainActor
public final class MurtiCacheCoordinator {
    private let renderLimit: Int
    private var renderCache: [String: MurtiNode] = [:]
    private var renderOrder: [String] = []            // LRU: most-recent last
    private var manifestScreens: [String: String] = [:]
    private var manifestSequence: Int = .min
    private var lastGood: [String: String] = [:]

    public init(renderLimit: Int) { self.renderLimit = renderLimit }

    // Render cache
    public func renderCached(_ key: String) -> MurtiNode? {
        guard let node = renderCache[key] else { return nil }
        touch(key); return node
    }
    public func storeRender(_ node: MurtiNode, for key: String) {
        renderCache[key] = node; touch(key)
        while renderOrder.count > renderLimit {
            renderCache[renderOrder.removeFirst()] = nil
        }
    }
    public func purgeRenderCache() { renderCache.removeAll(); renderOrder.removeAll() }
    private func touch(_ key: String) { renderOrder.removeAll { $0 == key }; renderOrder.append(key) }

    // Manifest
    public func version(for screenKey: String) -> String? { manifestScreens[screenKey] }
    @discardableResult
    public func apply(_ manifest: Manifest) -> Bool {
        guard manifest.sequence >= manifestSequence else { return false }
        manifestScreens = manifest.screens
        manifestSequence = manifest.sequence
        return true
    }

    // Last-good (for offline fallback)
    public func lastGoodVersion(_ screenKey: String) -> String? { lastGood[screenKey] }
    public func markGood(screenKey: String, version: String) { lastGood[screenKey] = version }
}
