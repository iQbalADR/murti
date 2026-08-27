import MurtiCore

/// A padded container with a background.
public struct Card: MurtiNodeConvertible {
    private let padding: Double?
    private let children: [MurtiNode]
    public init(padding: Double? = nil, @MurtiTreeBuilder children: () -> [MurtiNode]) {
        self.padding = padding
        self.children = children()
    }
    public func node() -> MurtiNode {
        var props: [String: MurtiValue] = [:]
        if let padding { props["padding"] = .number(padding) }
        return MurtiNode(type: "card", props: props, children: children)
    }
}
