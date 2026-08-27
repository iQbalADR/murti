import MurtiCore

public struct Button: MurtiNodeConvertible {
    private let title: String
    private let action: Action?
    private let a11yId: String?
    public init(_ title: String, action: Action? = nil, a11yId: String? = nil) {
        self.title = title
        self.action = action
        self.a11yId = a11yId
    }
    public func node() -> MurtiNode {
        var props: [String: MurtiValue] = ["title": .string(title)]
        if let a11yId { props["a11yId"] = .string(a11yId) }
        return MurtiNode(type: "button", props: props, action: action?.spec)
    }
}
