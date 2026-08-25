import Foundation

/// Cache configuration injected into the engine (Strategy + limits).
public struct MurtiCache: Sendable {
    public let store: any MurtiCacheStore
    public let cipher: any MurtiCacheCipher
    public var renderCacheLimit: Int
    public init(store: any MurtiCacheStore,
                cipher: any MurtiCacheCipher = PassthroughCipher(),
                renderCacheLimit: Int = 32) {
        self.store = store
        self.cipher = cipher
        self.renderCacheLimit = renderCacheLimit
    }
}
