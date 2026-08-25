import Foundation

/// A decoded JSON value — the closed value space that crosses the Murti JSON
/// boundary.
///
/// Keeping the value space closed (no arbitrary `Any`) is what makes
/// bounds-checking, sanitization, and `Sendable` conformance tractable.
public enum MurtiValue: Sendable, Hashable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case array([MurtiValue])
    case object([String: MurtiValue])
    case null
}

// MARK: - Typed access

public extension MurtiValue {
    var stringValue: String? { if case .string(let v) = self { return v }; return nil }
    var doubleValue: Double? { if case .number(let v) = self { return v }; return nil }
    var intValue: Int? { if case .number(let v) = self { return Int(v) }; return nil }
    var boolValue: Bool? { if case .bool(let v) = self { return v }; return nil }
    var arrayValue: [MurtiValue]? { if case .array(let v) = self { return v }; return nil }
    var objectValue: [String: MurtiValue]? { if case .object(let v) = self { return v }; return nil }

    /// How the value renders when interpolated into a `{{token}}`. Scalars only;
    /// arrays/objects/null interpolate to an empty string.
    var displayString: String {
        switch self {
        case .string(let s): return s
        case .bool(let b): return b ? "true" : "false"
        case .number(let n):
            if n.rounded() == n, abs(n) < 1e15 { return String(Int(n)) }
            return String(n)
        case .array, .object, .null: return ""
        }
    }
}

// MARK: - Codable

extension MurtiValue: Codable {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([MurtiValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: MurtiValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unsupported JSON value for MurtiValue"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let v): try container.encode(v)
        case .number(let v): try container.encode(v)
        case .string(let v): try container.encode(v)
        case .array(let v): try container.encode(v)
        case .object(let v): try container.encode(v)
        }
    }
}
