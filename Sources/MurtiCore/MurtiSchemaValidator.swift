import Foundation

/// Validation layers 2 (schema conformance) and the bounds JSON Schema can't
/// express. Pure and `Sendable` — it walks an already-decoded tree (layer 1) and
/// throws `MurtiError` on the first violation. Semantic checks (does a `type`
/// resolve, does a `screen`/`request` exist) and the render-time Null-Object
/// fallback are layers 3–4, elsewhere.
///
/// The component `type` vocabulary is OPEN, so this only checks that a type is a
/// well-formed identifier — never that it is registered.
public struct MurtiSchemaValidator: Sendable {
    public let bounds: MurtiBounds
    public let schemaMajor: Int

    public init(bounds: MurtiBounds = .default, schemaMajor: Int = 1) {
        self.bounds = bounds
        self.schemaMajor = schemaMajor
    }

    public func validate(_ payload: MurtiPayload) throws {
        try validateVersion(payload.schemaVersion)
        try requireIdentifier(payload.screen.key, "screen.key")
        try validate(root: payload.screen.root)
    }

    /// Validate a node tree without the payload envelope (handy for tests/tools).
    public func validate(root: MurtiNode) throws {
        var nodeCount = 0
        try validateNode(root, depth: 1, nodeCount: &nodeCount)
    }

    // MARK: - Node walk

    private func validateNode(_ node: MurtiNode, depth: Int, nodeCount: inout Int) throws {
        guard depth <= bounds.maxDepth else {
            throw MurtiError.bounds("tree depth exceeds \(bounds.maxDepth)")
        }
        nodeCount += 1
        guard nodeCount <= bounds.maxNodes else {
            throw MurtiError.bounds("node count exceeds \(bounds.maxNodes)")
        }

        guard isIdentifier(node.type, allowDot: true), node.type.count <= bounds.maxIdentifierLength else {
            throw MurtiError.schema("invalid component type '\(node.type)'")
        }
        if let id = node.id, id.count > bounds.maxIdentifierLength {
            throw MurtiError.bounds("node id length exceeds \(bounds.maxIdentifierLength)")
        }

        guard node.props.count <= bounds.maxProps else {
            throw MurtiError.bounds("props exceed \(bounds.maxProps)")
        }
        for value in node.props.values { try validateValue(value) }

        guard node.children.count <= bounds.maxChildren else {
            throw MurtiError.bounds("children exceed \(bounds.maxChildren)")
        }
        for child in node.children {
            try validateNode(child, depth: depth + 1, nodeCount: &nodeCount)
        }

        if let action = node.action { try validateAction(action, chainDepth: 1) }
    }

    private func validateValue(_ value: MurtiValue) throws {
        switch value {
        case .string(let string):
            guard string.count <= bounds.maxStringLength else {
                throw MurtiError.bounds("string length exceeds \(bounds.maxStringLength)")
            }
        case .array(let array):
            guard array.count <= bounds.maxArrayItems else {
                throw MurtiError.bounds("array items exceed \(bounds.maxArrayItems)")
            }
            for element in array { try validateValue(element) }
        case .object(let object):
            guard object.count <= bounds.maxProps else {
                throw MurtiError.bounds("object props exceed \(bounds.maxProps)")
            }
            for element in object.values { try validateValue(element) }
        case .number, .bool, .null:
            break
        }
    }

    private func validateAction(_ action: MurtiActionSpec, chainDepth: Int) throws {
        guard chainDepth <= bounds.maxChainDepth else {
            throw MurtiError.bounds("action chain depth exceeds \(bounds.maxChainDepth)")
        }
        switch action.type {
        case .navigate: try requireNamedTarget(action.screen, "navigate.screen")
        case .api:      try requireNamedTarget(action.request, "api.request")
        case .openURL:  try requireNamedTarget(action.link, "openURL.link")
        case .dismiss, .refresh: break
        }
        if let params = action.params {
            guard params.count <= bounds.maxProps else {
                throw MurtiError.bounds("params exceed \(bounds.maxProps)")
            }
            for value in params.values { try validateValue(value) }
        }
        if let onSuccess = action.onSuccess { try validateAction(onSuccess, chainDepth: chainDepth + 1) }
        if let onError = action.onError { try validateAction(onError, chainDepth: chainDepth + 1) }
    }

    // MARK: - Conformance helpers

    private func validateVersion(_ version: String) throws {
        let parts = version.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 2, let major = Int(parts[0]), Int(parts[1]) != nil else {
            throw MurtiError.schema("schemaVersion must be MAJOR.MINOR, got '\(version)'")
        }
        guard major == schemaMajor else {
            throw MurtiError.unsupportedVersion(version)
        }
    }

    private func requireNamedTarget(_ value: String?, _ label: String) throws {
        guard let value else { throw MurtiError.schema("\(label) is required") }
        try requireIdentifier(value, label)
    }

    private func requireIdentifier(_ value: String, _ label: String) throws {
        guard isIdentifier(value), value.count <= bounds.maxIdentifierLength else {
            throw MurtiError.schema("invalid identifier for \(label): '\(value)'")
        }
    }

    /// Mirrors the schema patterns: `^[A-Za-z][A-Za-z0-9_]*$` (dots allowed for
    /// namespaced component types). ASCII only — rejects URLs, paths, injection.
    private func isIdentifier(_ string: String, allowDot: Bool = false) -> Bool {
        guard !string.isEmpty else { return false }
        for (index, character) in string.enumerated() {
            let isAlpha = character.isASCII && character.isLetter
            if index == 0 {
                if !isAlpha { return false }
            } else {
                let isDigit = character.isASCII && character.isNumber
                let ok = isAlpha || isDigit || character == "_" || (allowDot && character == ".")
                if !ok { return false }
            }
        }
        return true
    }
}
