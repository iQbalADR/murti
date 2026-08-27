import Foundation
import MurtiCore

/// A screen authored in the DSL. Produces a `MurtiPayload` and can validate and
/// encode it to JSON.
public struct Screen {
    public let payload: MurtiPayload

    public init(_ key: String, schemaVersion: String = "1.0", root: () -> MurtiNodeConvertible) {
        payload = MurtiPayload(schemaVersion: schemaVersion,
                               screen: MurtiScreenSpec(key: key, root: root().node()))
    }

    /// Throws if the payload doesn't satisfy the schema and bounds.
    @discardableResult
    public func validated(with validator: MurtiSchemaValidator = MurtiSchemaValidator()) throws -> Screen {
        try validator.validate(payload)
        return self
    }

    /// Encode the payload to JSON bytes, with sorted keys for stable output.
    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(payload)
    }
}
