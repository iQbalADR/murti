import Testing
@testable import MurtiCore

@MainActor
@Suite("MurtiCacheCoordinator")
struct MurtiCacheCoordinatorTests {
    @Test func renderCacheLRUEvicts() {
        let c = MurtiCacheCoordinator(renderLimit: 2)
        c.storeRender(MurtiNode(type: "a"), for: "1")
        c.storeRender(MurtiNode(type: "b"), for: "2")
        _ = c.renderCached("1")                       // touch 1 → 2 is now LRU
        c.storeRender(MurtiNode(type: "c"), for: "3") // evicts 2
        #expect(c.renderCached("1")?.type == "a")
        #expect(c.renderCached("2") == nil)
        #expect(c.renderCached("3")?.type == "c")
    }

    @Test func manifestRejectsDowngrade() {
        let c = MurtiCacheCoordinator(renderLimit: 8)
        #expect(c.apply(Manifest(sequence: 5, screens: ["home": "v5"])) == true)
        #expect(c.version(for: "home") == "v5")
        #expect(c.apply(Manifest(sequence: 4, screens: ["home": "v4"])) == false) // older → rejected
        #expect(c.version(for: "home") == "v5")
        #expect(c.apply(Manifest(sequence: 6, screens: ["home": "v6"])) == true)
        #expect(c.version(for: "home") == "v6")
    }

    @Test func tracksLastGoodVersion() {
        let c = MurtiCacheCoordinator(renderLimit: 8)
        c.markGood(screenKey: "home", version: "v5")
        #expect(c.lastGoodVersion("home") == "v5")
    }
}
