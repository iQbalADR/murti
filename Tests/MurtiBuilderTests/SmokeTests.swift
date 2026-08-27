import Testing
@testable import MurtiBuilder

@Suite("MurtiBuilder smoke")
struct SmokeTests {
    @Test func moduleLoads() { #expect(MurtiBuilder.isAvailable) }
}
