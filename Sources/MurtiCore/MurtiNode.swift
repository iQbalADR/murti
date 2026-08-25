import Foundation

/// A decoded UI node — the Composite element the renderer walks.
///
/// `type` is an OPEN vocabulary: the component registry is extensible, so the
/// model accepts any type string. Whether it resolves to a real component is a
/// semantic / render-time concern, not a decode concern.
///
/// `id` is optional in the JSON; the renderer assigns stable SwiftUI identity
/// from `id ?? positional path`, so the data model never fabricates one.
public struct MurtiNode: Sendable, Hashable, Codable {
    public let id: String?
    public let type: String
    public let props: [String: MurtiValue]
    public let children: [MurtiNode]
    public let action: MurtiActionSpec?

    public init(
        id: String? = nil,
        type: String,
        props: [String: MurtiValue] = [:],
        children: [MurtiNode] = [],
        action: MurtiActionSpec? = nil
    ) {
        self.id = id
        self.type = type
        self.props = props
        self.children = children
        self.action = action
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, props, children, action
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        props = try c.decodeIfPresent([String: MurtiValue].self, forKey: .props) ?? [:]
        children = try c.decodeIfPresent([MurtiNode].self, forKey: .children) ?? []
        action = try c.decodeIfPresent(MurtiActionSpec.self, forKey: .action)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encode(type, forKey: .type)
        if !props.isEmpty { try c.encode(props, forKey: .props) }
        if !children.isEmpty { try c.encode(children, forKey: .children) }
        try c.encodeIfPresent(action, forKey: .action)
    }

    // MARK: - Typed prop accessors (defaulting; never throw)

    public func value(_ key: String) -> MurtiValue? { props[key] }
    public func string(_ key: String) -> String { props[key]?.stringValue ?? "" }
    public func int(_ key: String) -> Int { props[key]?.intValue ?? 0 }
    public func double(_ key: String) -> Double { props[key]?.doubleValue ?? 0 }
    public func bool(_ key: String) -> Bool { props[key]?.boolValue ?? false }
    public func array(_ key: String) -> [MurtiValue] { props[key]?.arrayValue ?? [] }
}
