import MurtiCore

public enum HAlignment: String { case leading, center, trailing }
public enum VAlignment: String { case top, center, bottom }

/// A vertical stack. Cross-axis alignment is horizontal.
public struct VStack: MurtiNodeConvertible {
    private let spacing: Double?
    private let alignment: HAlignment?
    private let children: [MurtiNode]
    public init(spacing: Double? = nil, alignment: HAlignment? = nil,
                @MurtiTreeBuilder children: () -> [MurtiNode]) {
        self.spacing = spacing
        self.alignment = alignment
        self.children = children()
    }
    public func node() -> MurtiNode {
        var props: [String: MurtiValue] = [:]
        if let spacing { props["spacing"] = .number(spacing) }
        if let alignment { props["alignment"] = .string(alignment.rawValue) }
        return MurtiNode(type: "vstack", props: props, children: children)
    }
}

/// A horizontal stack. Cross-axis alignment is vertical.
public struct HStack: MurtiNodeConvertible {
    private let spacing: Double?
    private let alignment: VAlignment?
    private let children: [MurtiNode]
    public init(spacing: Double? = nil, alignment: VAlignment? = nil,
                @MurtiTreeBuilder children: () -> [MurtiNode]) {
        self.spacing = spacing
        self.alignment = alignment
        self.children = children()
    }
    public func node() -> MurtiNode {
        var props: [String: MurtiValue] = [:]
        if let spacing { props["spacing"] = .number(spacing) }
        if let alignment { props["alignment"] = .string(alignment.rawValue) }
        return MurtiNode(type: "hstack", props: props, children: children)
    }
}
