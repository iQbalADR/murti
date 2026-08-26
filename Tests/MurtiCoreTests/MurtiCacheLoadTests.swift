import CryptoKit
import Foundation
import Testing
@testable import MurtiCore

@MainActor
@Suite("Cached load")
struct MurtiCacheLoadTests {
    let key = Curve25519.Signing.PrivateKey()
    var verifier: Ed25519Verifier { try! Ed25519Verifier(publicKey: key.publicKey.rawRepresentation) }
    func envelope(_ type: String) -> Data {
        let payload = Data(#"{"schemaVersion":"1.0","screen":{"key":"home","root":{"type":"\#(type)"}}}"#.utf8)
        let sig = try! key.signature(for: payload)
        return try! JSONEncoder().encode(MurtiEnvelope(schemaVersion: "1.0", alg: "ed25519", payload: payload, signature: sig))
    }

    func makeEngine(store: any MurtiCacheStore, fetches: FetchCounter) -> MurtiEngine {
        let factory = MurtiScreenFactory()
        factory.register("home") { await fetches.bump(); return await self.envelope("text") }
        return MurtiEngine(
            componentFactory: .withBuiltins, screenFactory: factory,
            security: .signed(verifier),
            cache: MurtiCache(store: store, cipher: PassthroughCipher())
        )
    }

    @Test func missFetchesAndStores_thenDiskHitAvoidsRefetch() async {
        let store = MemoryCacheStore(); let fetches = FetchCounter()
        let engine = makeEngine(store: store, fetches: fetches)
        engine.coordinator?.purgeRenderCache()
        _ = await engine.load(.key("home"))          // miss → fetch + store
        engine.coordinator?.purgeRenderCache()        // drop in-memory tier
        guard case .loaded(let root) = await engine.load(.key("home")) else { Issue.record("loaded"); return }
        #expect(root.type == "text")
        #expect(await fetches.count == 1)             // 2nd load hit disk, no refetch
    }

    @Test func renderCacheAvoidsDiskAndFetch() async {
        let store = MemoryCacheStore(); let fetches = FetchCounter()
        let engine = makeEngine(store: store, fetches: fetches)
        _ = await engine.load(.key("home"))          // fetch #1, fills render cache
        _ = await engine.load(.key("home"))          // render hit
        #expect(await fetches.count == 1)
    }

    @Test func tamperedDiskEntryIsRejectedAndEvicted() async {
        let store = MemoryCacheStore(); let fetches = FetchCounter()
        let engine = makeEngine(store: store, fetches: fetches)
        _ = await engine.load(.key("home")); engine.coordinator?.purgeRenderCache()
        await store.store(Data("corrupted".utf8), for: cacheKey("home", "unversioned"))
        _ = await engine.load(.key("home"))          // re-verify fails → evict → refetch
        #expect(await fetches.count == 2)
    }

    @Test func offlineServesLastGoodAcrossVersionBump() async {
        let store = MemoryCacheStore(); let fetches = FetchCounter()
        let factory = MurtiScreenFactory()
        factory.register("home") { await fetches.bump()
            if await fetches.count == 1 { return await self.envelope("text") }
            throw MurtiError.network(status: nil) }                 // fail after the first success
        let engine = MurtiEngine(componentFactory: .withBuiltins, screenFactory: factory,
                                 security: .signed(verifier),
                                 cache: MurtiCache(store: store, cipher: PassthroughCipher()))
        _ = await engine.load(.key("home"))                         // fetch #1 → cached + marked good under "unversioned"
        engine.coordinator?.purgeRenderCache()
        engine.coordinator?.apply(Manifest(sequence: 1, screens: ["home": "v2"]))   // bump version → next disk key misses
        guard case .loaded(let root) = await engine.load(.key("home")) else {
            Issue.record("expected .loaded from offline last-good"); return
        }
        #expect(root.type == "text")
        #expect(await fetches.count == 2)                           // fetch #2 was attempted (threw) → offline served
    }

    @Test func forgedFreshPayloadIsNotMaskedAsStale() async {
        let attacker = Curve25519.Signing.PrivateKey()
        let store = MemoryCacheStore(); let fetches = FetchCounter()
        let factory = MurtiScreenFactory()
        factory.register("home") { await fetches.bump()
            if await fetches.count == 1 { return await self.envelope("text") }   // good → last-good on disk
            let payload = Data(#"{"schemaVersion":"1.0","screen":{"key":"home","root":{"type":"text"}}}"#.utf8)
            let sig = try! attacker.signature(for: payload)                        // forged (wrong key)
            return try! JSONEncoder().encode(MurtiEnvelope(schemaVersion: "1.0", alg: "ed25519", payload: payload, signature: sig))
        }
        let engine = MurtiEngine(componentFactory: .withBuiltins, screenFactory: factory,
                                 security: .signed(verifier),
                                 cache: MurtiCache(store: store, cipher: PassthroughCipher()))
        _ = await engine.load(.key("home"))                                        // good load → last-good "unversioned"
        engine.coordinator?.purgeRenderCache()
        engine.coordinator?.apply(Manifest(sequence: 1, screens: ["home": "v2"]))  // next key misses disk → refetch
        if case .failed = await engine.load(.key("home")) {} else {
            Issue.record("a forged FRESH payload must surface as .failed, not be masked as offline/stale")
        }
    }

    @Test func renderTierServesEvenWhenDiskEntryCorrupt() async {
        let store = MemoryCacheStore(); let fetches = FetchCounter()
        let engine = makeEngine(store: store, fetches: fetches)
        _ = await engine.load(.key("home"))                       // fills render + disk
        await store.store(Data("corrupt".utf8), for: cacheKey("home", "unversioned"))  // corrupt disk, keep render
        _ = await engine.load(.key("home"))                        // render hit, disk never consulted
        #expect(await fetches.count == 1)
    }

    @Test func offlineWithTamperedLastGoodFailsClosed() async {
        let store = MemoryCacheStore(); let fetches = FetchCounter()
        let factory = MurtiScreenFactory()
        factory.register("home") { await fetches.bump()
            if await fetches.count == 1 { return await self.envelope("text") }
            throw MurtiError.network(status: nil) }
        let engine = MurtiEngine(componentFactory: .withBuiltins, screenFactory: factory,
                                 security: .signed(verifier),
                                 cache: MurtiCache(store: store, cipher: PassthroughCipher()))
        _ = await engine.load(.key("home"))                        // good load, marks good "unversioned"
        engine.coordinator?.purgeRenderCache()
        engine.coordinator?.apply(Manifest(sequence: 1, screens: ["home": "v2"]))   // next key misses disk
        await store.store(Data("corrupt".utf8), for: cacheKey("home", "unversioned"))  // corrupt last-good
        if case .failed = await engine.load(.key("home")) {} else { Issue.record("tampered last-good must fail closed") }
    }

    @Test func prefetchWarmsCacheSoLoadDoesNotRefetch() async {
        let store = MemoryCacheStore(); let fetches = FetchCounter()
        let engine = makeEngine(store: store, fetches: fetches)
        await engine.prefetch(["home"])                 // warms render + disk (fetch #1)
        engine.coordinator?.purgeRenderCache()
        guard case .loaded = await engine.load(.key("home")) else { Issue.record("served from disk"); return }
        #expect(await fetches.count == 1)               // load served from disk, no refetch
    }
}

actor FetchCounter { private(set) var count = 0; func bump() { count += 1 } }
