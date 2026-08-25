import Testing
@testable import MurtiCore

@MainActor
@Suite("MurtiCache wiring")
struct MurtiCacheWiringTests {
    @Test func engineBuildsCoordinatorWhenCachePresent() {
        let engine = MurtiEngine(
            componentFactory: .withBuiltins,
            screenFactory: MurtiScreenFactory(),
            cache: MurtiCache(store: MemoryCacheStore(), cipher: PassthroughCipher())
        )
        #expect(engine.coordinator != nil)
    }
    @Test func noCacheMeansNoCoordinator() {
        let engine = MurtiEngine(componentFactory: .withBuiltins, screenFactory: MurtiScreenFactory())
        #expect(engine.coordinator == nil)
    }
}
