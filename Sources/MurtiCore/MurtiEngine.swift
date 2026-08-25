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
    /// (Signature verification and schema validation will wrap the decode here.)
    public func load(_ source: ScreenSource) async -> LoadState {
        do {
            let bytes = try await sourceData(source)
            let payloadData = try unwrap(bytes)      // verify signature / unwrap envelope per policy
            let payload = try JSONDecoder().decode(MurtiPayload.self, from: payloadData)
            try validator.validate(payload)          // layer 2 (schema) + bounds
            return .loaded(payload.screen.root)
        } catch let error as MurtiError {
            return .failed(error)
        } catch let error as DecodingError {
            return .failed(.decode(String(describing: error)))
        } catch {
            return .failed(.decode(error.localizedDescription))
        }
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
