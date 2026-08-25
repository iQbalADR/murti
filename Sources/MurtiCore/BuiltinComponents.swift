import SwiftUI

// The built-in set: text, image, vstack, hstack, button, card. Each is a tidy,
// single-type component — the template third-party components follow.

// MARK: - text

struct TextComponent: MurtiComponent {
    static let type = "text"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        AnyView(
            Text(context.resolve(node.string("value")))
                .font(Self.font(node.string("style")))
                .murtiAccessibility(node, context: context)
        )
    }
    private static func font(_ style: String) -> Font {
        switch style {
        case "title": .title
        case "headline": .headline
        case "caption": .caption
        default: .body
        }
    }
}

// MARK: - image

struct ImageComponent: MurtiComponent {
    static let type = "image"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        // `systemName` renders an SF Symbol; `name` renders a bundled asset. A
        // named remote `source` (allow-listed, never a raw URL) is supplied by the
        // host, not fetched here.
        let systemName = node.string("systemName")
        if !systemName.isEmpty {
            return AnyView(
                Image(systemName: systemName)
                    .imageScale(.large)
                    .murtiAccessibility(node, context: context)
            )
        }
        return AnyView(
            Image(node.string("name"))
                .resizable()
                .aspectRatio(contentMode: node.string("contentMode") == "fill" ? .fill : .fit)
                .murtiAccessibility(node, context: context)
        )
    }
}

// MARK: - vstack / hstack

struct VStackComponent: MurtiComponent {
    static let type = "vstack"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        AnyView(
            VStack(alignment: horizontalAlignment(node.string("alignment")), spacing: spacing(node)) {
                MurtiChildren(node: node, context: context)
            }
            .murtiAccessibility(node, context: context)
        )
    }
}

struct HStackComponent: MurtiComponent {
    static let type = "hstack"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        AnyView(
            HStack(alignment: verticalAlignment(node.string("alignment")), spacing: spacing(node)) {
                MurtiChildren(node: node, context: context)
            }
            .murtiAccessibility(node, context: context)
        )
    }
}

// MARK: - button

struct ButtonComponent: MurtiComponent {
    static let type = "button"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        AnyView(
            Button(context.resolve(node.string("title"))) {
                if let action = node.action { context.dispatch(action) }
            }
            .murtiAccessibility(node, context: context)
        )
    }
}

// MARK: - card

struct CardComponent: MurtiComponent {
    static let type = "card"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        let padding = node.value("padding")?.doubleValue.map { CGFloat($0) } ?? 16
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                MurtiChildren(node: node, context: context)
            }
            .padding(padding)
            .background(Color.secondary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .murtiAccessibility(node, context: context)
        )
    }
}

// MARK: - Composite child rendering

/// Renders a node's children, giving each stable identity from `id ?? position`.
struct MurtiChildren: View {
    let node: MurtiNode
    let context: MurtiRenderContext

    var body: some View {
        ForEach(identifiedChildren) { entry in
            context.view(for: entry.node)
        }
    }

    private struct Entry: Identifiable { let id: String; let node: MurtiNode }
    private var identifiedChildren: [Entry] {
        node.children.enumerated().map { index, child in
            Entry(id: child.id ?? String(index), node: child)
        }
    }
}

// MARK: - Layout prop helpers

private func spacing(_ node: MurtiNode) -> CGFloat? {
    node.value("spacing")?.doubleValue.map { CGFloat($0) }
}

private func horizontalAlignment(_ value: String) -> HorizontalAlignment {
    switch value {
    case "leading": .leading
    case "trailing": .trailing
    default: .center
    }
}

private func verticalAlignment(_ value: String) -> VerticalAlignment {
    switch value {
    case "top": .top
    case "bottom": .bottom
    default: .center
    }
}
