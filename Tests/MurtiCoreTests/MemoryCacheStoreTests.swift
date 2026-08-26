import Foundation
import Testing
@testable import MurtiCore

@Suite("MemoryCacheStore")
struct MemoryCacheStoreTests {
    @Test func storesReadsAndRemoves() async {
        let store = MemoryCacheStore()
        await store.store(Data("x".utf8), for: "k")
        #expect(await store.data(for: "k") == Data("x".utf8))
        await store.remove("k")
        #expect(await store.data(for: "k") == nil)
    }
}
