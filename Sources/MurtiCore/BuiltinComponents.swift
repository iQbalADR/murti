import SwiftUI

// The built-in set: text, image, vstack, hstack, button, card. Each is a tidy,
// single-type component — the template third-party components follow.

// MARK: - text

struct TextComponent: MurtiComponent {
    static let type = "text"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        AnyView(
            Text(context.resolve(node.string("value")))
                .font(Self.font(node))
                .modifier(MurtiForegroundColor(hex: node.string("color")))
                .murtiStyle(node)
                .murtiAccessibility(node, context: context)
        )
    }
    /// The font from `style`, with an optional explicit `size` and `weight`.
    private static func font(_ node: MurtiNode) -> Font {
        let weight = murtiFontWeight(node.string("weight"))
        if let size = node.value("size")?.doubleValue {
            return .system(size: size, weight: weight ?? .regular)
        }
        let base = styleFont(node.string("style"))
        return weight.map { base.weight($0) } ?? base
    }
    private static func styleFont(_ style: String) -> Font {
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
                    .murtiStyle(node)
                    .murtiAccessibility(node, context: context)
            )
        }
        return AnyView(
            Image(node.string("name"))
                .resizable()
                .aspectRatio(contentMode: node.string("contentMode") == "fill" ? .fill : .fit)
                .murtiStyle(node)
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
            .murtiStyle(node)
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
            .murtiStyle(node)
            .murtiAccessibility(node, context: context)
        )
    }
}

// MARK: - zstack

/// Overlays children. With a `width`/`height` (the source frame's size) and `x`/`y`/
/// `width`/`height` on each child, it places them at absolute positions and scales
/// the whole frame to the available width — reproducing a Figma frame that layers
/// content instead of flowing it. Without a frame size it's a plain centered overlay.
struct ZStackComponent: MurtiComponent {
    static let type = "zstack"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        let width = node.value("width")?.doubleValue ?? 0
        let height = node.value("height")?.doubleValue ?? 0
        guard width > 0, height > 0 else {
            return AnyView(
                ZStack { MurtiChildren(node: node, context: context) }
                    .murtiStyle(node)
                    .murtiAccessibility(node, context: context)
            )
        }
        let children = node.children
        return AnyView(
            GeometryReader { proxy in
                let scale = proxy.size.width / width
                ZStack(alignment: .topLeading) {
                    ForEach(Array(children.enumerated()), id: \.offset) { _, child in
                        let box = childBox(child, frameWidth: width, frameHeight: height)
                        context.view(for: child)
                            .frame(width: box.width, height: box.height)
                            .position(x: box.midX, y: box.midY)
                    }
                }
                .frame(width: width, height: height, alignment: .topLeading)
                .scaleEffect(scale, anchor: .topLeading)
            }
            .aspectRatio(width / height, contentMode: .fit)
            .murtiStyle(node)
            .murtiAccessibility(node, context: context)
        )
    }
}

func childBox(_ node: MurtiNode, frameWidth: Double, frameHeight: Double) -> CGRect {
    let x = node.value("x")?.doubleValue ?? 0
    let y = node.value("y")?.doubleValue ?? 0
    let w = node.value("width")?.doubleValue ?? frameWidth
    let h = node.value("height")?.doubleValue ?? frameHeight
    return CGRect(x: x, y: y, width: w, height: h)
}

// MARK: - button

struct ButtonComponent: MurtiComponent {
    static let type = "button"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        AnyView(
            Button(context.resolve(node.string("title"))) {
                if let action = node.action { context.dispatch(action) }
            }
            .murtiStyle(node)
            .murtiAccessibility(node, context: context)
        )
    }
}

// MARK: - card

struct CardComponent: MurtiComponent {
    static let type = "card"
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView {
        // A card's grey box is the default; `background`, `cornerRadius`, `padding`,
        // and `foreground` props override it.
        let padding = node.value("padding")?.doubleValue.map { CGFloat($0) } ?? 16
        let radius = node.value("cornerRadius")?.doubleValue.map { CGFloat($0) } ?? 12
        let background = Color(murtiHex: node.string("background")) ?? Color.secondary.opacity(0.12)
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                MurtiChildren(node: node, context: context)
            }
            .padding(padding)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: radius))
            .modifier(MurtiForegroundColor(hex: node.string("foreground")))
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
