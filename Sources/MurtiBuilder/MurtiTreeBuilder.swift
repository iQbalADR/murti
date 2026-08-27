import MurtiCore

/// A value that produces one `MurtiNode` — anything the DSL can place in a tree.
public protocol MurtiNodeConvertible {
    func node() -> MurtiNode
}

/// Collects child components into `[MurtiNode]`. Supports `if` and `for` inside a
/// builder closure.
@resultBuilder
public enum MurtiTreeBuilder {
    public static func buildExpression(_ expression: MurtiNodeConvertible) -> [MurtiNode] { [expression.node()] }
    public static func buildExpression(_ expression: [MurtiNodeConvertible]) -> [MurtiNode] { expression.map { $0.node() } }
    public static func buildBlock(_ components: [MurtiNode]...) -> [MurtiNode] { components.flatMap { $0 } }
    public static func buildOptional(_ component: [MurtiNode]?) -> [MurtiNode] { component ?? [] }
    public static func buildEither(first component: [MurtiNode]) -> [MurtiNode] { component }
    public static func buildEither(second component: [MurtiNode]) -> [MurtiNode] { component }
    public static func buildArray(_ components: [[MurtiNode]]) -> [MurtiNode] { components.flatMap { $0 } }
}
