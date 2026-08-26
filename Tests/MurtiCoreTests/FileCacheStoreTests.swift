import Foundation
import Testing
@testable import MurtiCore

@Suite("FileCacheStore")
struct FileCacheStoreTests {
    @Test func persistsAndRemovesOnDisk() async throws {
        let dir = URL.temporaryDirectory.appending(path: "murti-cache-\(UUID().uuidString)")
        let store = FileCacheStore(directory: dir)
        await store.store(Data("disk".utf8), for: "k")
        #expect(await store.data(for: "k") == Data("disk".utf8))
        await store.remove("k")
        #expect(await store.data(for: "k") == nil)
    }

    @Test func rejectsPathTraversalKeys() async {
        let dir = URL.temporaryDirectory.appending(path: "murti-cache-\(UUID().uuidString)")
        let store = FileCacheStore(directory: dir)
        await store.store(Data("x".utf8), for: "../escape")
        #expect(await store.data(for: "../escape") == nil)
        #expect(await store.data(for: "a/b") == nil)
    }
}
