import SwiftUI

extension View {
    /// Apply Murti's shared accessibility props (`a11yLabel`, `a11yId`,
    /// `a11yTraits`) from a node. Defaults are left untouched when a prop is
    /// absent — never worse than SwiftUI's native behavior.
    func murtiAccessibility(_ node: MurtiNode, context: MurtiRenderContext) -> some View {
        let label = node.string("a11yLabel")
        return self
            .accessibilityAddTraits(accessibilityTraits(from: node.array("a11yTraits").compactMap(\.stringValue)))
            .modifier(ConditionalIdentifier(id: node.string("a11yId")))
            .modifier(ConditionalLabel(label: label.isEmpty ? nil : context.resolve(label)))
    }
}

private func accessibilityTraits(from names: [String]) -> AccessibilityTraits {
    var traits = AccessibilityTraits()
    for name in names {
        switch name {
        case "button": traits.formUnion(.isButton)
        case "header": traits.formUnion(.isHeader)
        case "image": traits.formUnion(.isImage)
        case "link": traits.formUnion(.isLink)
        default: break
        }
    }
    return traits
}

private struct ConditionalLabel: ViewModifier {
    let label: String?
    func body(content: Content) -> some View {
        if let label {
            content.accessibilityLabel(Text(label))
        } else {
            content
        }
    }
}

private struct ConditionalIdentifier: ViewModifier {
    let id: String
    func body(content: Content) -> some View {
        if id.isEmpty {
            content
        } else {
            content.accessibilityIdentifier(id)
        }
    }
}
