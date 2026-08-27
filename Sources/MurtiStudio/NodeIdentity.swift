import MurtiCore

extension MurtiNode {
    /// Non-optional id for list identity. The editing tree always has ids.
    var editorID: String { id ?? "" }

    /// Children for `OutlineGroup` — nil for leaves so no empty disclosure shows.
    var outlineChildren: [MurtiNode]? { children.isEmpty ? nil : children }

    /// A short label for the outline row.
    var outlineLabel: String {
        switch type {
        case "text": return "text: \(string("value"))"
        case "button": return "button: \(string("title"))"
        default: return type
        }
    }
}
