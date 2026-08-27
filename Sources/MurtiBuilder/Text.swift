import MurtiCore

public enum TextStyle: String { case title, headline, caption, body }

/// A text component. Mirrors SwiftUI's name; author screen files that import
/// MurtiBuilder without SwiftUI.
public struct Text: MurtiNodeConvertible {
    private let value: String
    private let style: TextStyle?
    private let a11yLabel: String?
    private let a11yId: String?

    public init(_ value: String, style: TextStyle? = nil, a11yLabel: String? = nil, a11yId: String? = nil) {
        self.value = value
        self.style = style
        self.a11yLabel = a11yLabel
        self.a11yId = a11yId
    }

    public func node() -> MurtiNode {
        var props: [String: MurtiValue] = ["value": .string(value)]
        if let style { props["style"] = .string(style.rawValue) }
        if let a11yLabel { props["a11yLabel"] = .string(a11yLabel) }
        if let a11yId { props["a11yId"] = .string(a11yId) }
        return MurtiNode(type: "text", props: props)
    }
}
