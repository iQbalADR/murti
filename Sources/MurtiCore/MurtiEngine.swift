import Foundation

/// The composition root: the engine RECEIVES its factories, validator, and
/// dispatcher (pure DI, no global singletons). `load` verifies, decodes, and
/// validates a source into a screen root, failing closed on any error.
@MainActor
public struct MurtiEngine {
    public let componentFactory: MurtiComponentFactory
    public let screenFactory: MurtiScreenFactory
    public let actionDispatcher: MurtiActionDispatcher
    public let validator: MurtiSchemaValidator
    public let security: PayloadSecurity
    public let cache: MurtiCache?
    public let coordinator: MurtiCacheCoordinator?
    let namedResolver: (@Sendable (String) async throws -> Data)?

    public init(
        componentFactory: MurtiComponentFactory,
        screenFactory: MurtiScreenFactory,
        actionDispatcher: MurtiActionDispatcher = MurtiActionDispatcher(),
        validator: MurtiSchemaValidator = MurtiSchemaValidator(),
        security: PayloadSecurity = .insecureDevelopment,
        cache: MurtiCache? = nil,
        namedResolver: (@Sendable (String) async throws -> Data)? = nil
    ) {
        self.componentFactory = componentFactory
        self.screenFactory = screenFactory
        self.actionDispatcher = actionDispatcher
        self.validator = validator
        self.security = security
        self.cache = cache
        self.coordinator = cache.map { MurtiCacheCoordinator(renderLimit: $0.renderCacheLimit) }
        self.namedResolver = namedResolver
    }

    /// The renderer over the registered components.
    public var renderer: MurtiRenderer { MurtiRenderer(factory: componentFactory) }

    /// Resolve a source to its screen root, failing closed on any error.
    /// Key sources go through the cache tiers (render → disk → fetch, with an
    /// offline last-good fallback); other sources fetch and materialize directly.
    public func load(_ source: ScreenSource) async -> LoadState {
        do {
            if case .key(let screenKey) = source, let cache, let coordinator {
                return .loaded(try await loadCached(screenKey, cache: cache, coordinator: coordinator))
            }
            return .loaded(try await materialize(sourceData(source)))
        } catch let error as MurtiError {
            return .failed(error)
        } catch let error as DecodingError {
            return .failed(.decode(String(describing: error)))
        } catch {
            return .failed(.decode(error.localizedDescription))
        }
    }

    /// Serve a keyed screen through the cache tiers, verifying on every path so a
    /// poisoned disk entry is caught and evicted. Render hit → disk hit (re-verify)
    /// → fetch (store + record last-good) → offline fallback to the last-good version.
    private func loadCached(_ screenKey: String, cache: MurtiCache, coordinator: MurtiCacheCoordinator) async throws -> MurtiNode {
        let version = coordinator.version(for: screenKey) ?? "unversioned"
        let key = cacheKey(screenKey, version)

        if let node = coordinator.renderCached(key) { return node }                      // render tier

        if let sealed = await cache.store.data(for: key) {                               // disk tier
            if let node = try? materializeSealed(sealed, cache: cache) {                 // re-verify
                coordinator.storeRender(node, for: key)
                coordinator.markGood(screenKey: screenKey, version: version)
                return node
            }
            await cache.store.remove(key)                                                // tampered → evict
        }

        do {                                                                              // fetch
            let raw = try await screenFactory.data(for: screenKey)
            let node = try materialize(raw)
            await cache.store.store(try cache.cipher.seal(raw), for: key)
            coordinator.storeRender(node, for: key)
            coordinator.markGood(screenKey: screenKey, version: version)
            return node
        } catch {
            if let good = coordinator.lastGoodVersion(screenKey) {                        // offline fallback
                let goodKey = cacheKey(screenKey, good)
                if let sealed = await cache.store.data(for: goodKey), let node = try? materializeSealed(sealed, cache: cache) {
                    coordinator.storeRender(node, for: goodKey)
                    return node
                }
            }
            throw error
        }
    }

    /// Open (decrypt if a cipher is configured) then verify + validate cached bytes.
    private func materializeSealed(_ sealed: Data, cache: MurtiCache) throws -> MurtiNode {
        try materialize(cache.cipher.open(sealed))   // decrypt (if any) then verify + validate
    }

    private func sourceData(_ source: ScreenSource) async throws -> Data {
        switch source {
        case .inline(let data):
            return data
        case .key(let key):
            return try await screenFactory.data(for: key)
        case .named(let name):
            guard let namedResolver else { throw MurtiError.unknownScreen(name) }
            return try await namedResolver(name)
        }
    }

    /// Verify (per policy) → decode → validate → screen root. Reused by fetch and cache.
    private func materialize(_ rawBytes: Data) throws -> MurtiNode {
        let payloadData = try unwrap(rawBytes)
        let payload = try JSONDecoder().decode(MurtiPayload.self, from: payloadData)
        try validator.validate(payload)
        return payload.screen.root
    }

    /// Verify/unwrap the raw bytes into the plaintext payload bytes, per policy.
    /// Verification happens here (on every load, including from cache) — not at
    /// download — so a poisoned cache is caught too.
    private func unwrap(_ bytes: Data) throws -> Data {
        switch security {
        case .insecureDevelopment:
            // Accept a bare payload, or an envelope whose signature is not checked.
            if let envelope = try? JSONDecoder().decode(MurtiEnvelope.self, from: bytes) {
                return envelope.payload
            }
            return bytes
        case .signed(let verifier):
            guard let envelope = try? JSONDecoder().decode(MurtiEnvelope.self, from: bytes) else {
                throw MurtiError.signatureInvalid   // required-but-unsigned → reject
            }
            guard verifier.verify(payload: envelope.payload, signature: envelope.signature) else {
                throw MurtiError.signatureInvalid
            }
            return envelope.payload
        }
    }
}
