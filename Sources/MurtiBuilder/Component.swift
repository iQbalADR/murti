import MurtiCore

/// Author any component `type` the renderer might have, including third-party or
/// custom ones. This is the escape hatch for Murti's open component registry.
public func component(_ type: String, _ props: [String: MurtiValue] = [:],
                      @MurtiTreeBuilder children: () -> [MurtiNode] = { [] }) -> MurtiNodeConvertible {
    RawComponent(type: type, props: props, children: children())
}

private struct RawComponent: MurtiNodeConvertible {
    let type: String
    let props: [String: MurtiValue]
    let children: [MurtiNode]
    func node() -> MurtiNode { MurtiNode(type: type, props: props, children: children) }
}
