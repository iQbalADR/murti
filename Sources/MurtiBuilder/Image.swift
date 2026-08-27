import MurtiCore

public struct Image: MurtiNodeConvertible {
    private let props: [String: MurtiValue]

    /// An SF Symbol image.
    public init(systemName: String) { props = ["systemName": .string(systemName)] }

    /// A bundled asset image.
    public init(name: String, contentMode: String? = nil) {
        var props: [String: MurtiValue] = ["name": .string(name)]
        if let contentMode { props["contentMode"] = .string(contentMode) }
        self.props = props
    }

    public func node() -> MurtiNode { MurtiNode(type: "image", props: props) }
}
