import Foundation

/// The closed action vocabulary. A payload cannot express arbitrary behavior —
/// it can only pick one of these.
public enum ActionType: String, Sendable, Codable, CaseIterable {
    case navigate
    case api
    case dismiss
    case refresh
    case openURL
}

/// The *data* form of an action; the dispatcher turns it into behavior. Targets
/// are named references — a screen key, a named request, a named link — never a
/// raw URL.
///
/// `onSuccess`/`onError` form a bounded LINEAR chain, not an arbitrary tree.
public struct MurtiActionSpec: Sendable, Hashable, Codable {
    public let type: ActionType
    public let screen: String?    // navigate → a screen key
    public let request: String?   // api → an allow-listed named request
    public let link: String?      // openURL → an allow-listed named link
    public let params: [String: MurtiValue]?

    public var onSuccess: MurtiActionSpec? { onSuccessBox?.value }
    public var onError: MurtiActionSpec? { onErrorBox?.value }

    // Heap-boxed so this value type can (bounded) recursively contain itself.
    private let onSuccessBox: Box?
    private let onErrorBox: Box?

    public init(
        type: ActionType,
        screen: String? = nil,
        request: String? = nil,
        link: String? = nil,
        params: [String: MurtiValue]? = nil,
        onSuccess: MurtiActionSpec? = nil,
        onError: MurtiActionSpec? = nil
    ) {
        self.type = type
        self.screen = screen
        self.request = request
        self.link = link
        self.params = params
        self.onSuccessBox = onSuccess.map(Box.init)
        self.onErrorBox = onError.map(Box.init)
    }

    private enum CodingKeys: String, CodingKey {
        case type, screen, request, link, params, onSuccess, onError
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        type = try c.decode(ActionType.self, forKey: .type)
        screen = try c.decodeIfPresent(String.self, forKey: .screen)
        request = try c.decodeIfPresent(String.self, forKey: .request)
        link = try c.decodeIfPresent(String.self, forKey: .link)
        params = try c.decodeIfPresent([String: MurtiValue].self, forKey: .params)
        onSuccessBox = try c.decodeIfPresent(Box.self, forKey: .onSuccess)
        onErrorBox = try c.decodeIfPresent(Box.self, forKey: .onError)
    }

    public func encode(to encoder: any Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(type, forKey: .type)
        try c.encodeIfPresent(screen, forKey: .screen)
        try c.encodeIfPresent(request, forKey: .request)
        try c.encodeIfPresent(link, forKey: .link)
        try c.encodeIfPresent(params, forKey: .params)
        try c.encodeIfPresent(onSuccessBox, forKey: .onSuccess)
        try c.encodeIfPresent(onErrorBox, forKey: .onError)
    }

    /// Reference box that breaks the recursive value-type cycle while preserving
    /// value semantics (it is immutable and never shared mutably).
    private final class Box: Codable, Hashable, @unchecked Sendable {
        let value: MurtiActionSpec
        init(_ value: MurtiActionSpec) { self.value = value }
        init(from decoder: any Decoder) throws { value = try MurtiActionSpec(from: decoder) }
        func encode(to encoder: any Encoder) throws { try value.encode(to: encoder) }
        static func == (lhs: Box, rhs: Box) -> Bool { lhs.value == rhs.value }
        func hash(into hasher: inout Hasher) { hasher.combine(value) }
    }
}
