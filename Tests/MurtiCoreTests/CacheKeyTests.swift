import Testing
@testable import MurtiCore

@Suite("cacheKey")
struct CacheKeyTests {
    @Test func deterministicAndVersioned() {
        #expect(cacheKey("dashboard", "v7") == cacheKey("dashboard", "v7"))
        #expect(cacheKey("dashboard", "v7") != cacheKey("dashboard", "v8"))
        #expect(cacheKey("dashboard", "v7").count == 64)   // sha256 hex
    }
}
