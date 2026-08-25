import Foundation

/// Rendering bounds — the DoS defense. They cap worst-case decode / validate /
/// render cost regardless of what an authentic-but-malicious payload asks for.
///
/// Some (string length, prop/child/array counts, identifier length) are also
/// expressed in `murti.schema.json`; the client enforces ALL of them because it
/// cannot trust that the server ran the schema. Depth, total node count, and
/// action-chain depth are client-only — JSON Schema cannot express recursion
/// limits.
public struct MurtiBounds: Sendable, Hashable {
    public var maxDepth: Int
    public var maxNodes: Int
    public var maxStringLength: Int
    public var maxProps: Int
    public var maxChildren: Int
    public var maxArrayItems: Int
    public var maxIdentifierLength: Int
    public var maxChainDepth: Int

    public init(
        maxDepth: Int = 32,
        maxNodes: Int = 5000,
        maxStringLength: Int = 4096,
        maxProps: Int = 64,
        maxChildren: Int = 256,
        maxArrayItems: Int = 512,
        maxIdentifierLength: Int = 128,
        maxChainDepth: Int = 4
    ) {
        self.maxDepth = maxDepth
        self.maxNodes = maxNodes
        self.maxStringLength = maxStringLength
        self.maxProps = maxProps
        self.maxChildren = maxChildren
        self.maxArrayItems = maxArrayItems
        self.maxIdentifierLength = maxIdentifierLength
        self.maxChainDepth = maxChainDepth
    }

    public static let `default` = MurtiBounds()
}
