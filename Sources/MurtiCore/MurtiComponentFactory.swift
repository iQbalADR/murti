import SwiftUI

/// The one registry: a `type` string → a component (Factory pattern). One
/// registry, many small components — never a registry per component.
@MainActor
public final class MurtiComponentFactory {
    private var components: [String: any MurtiComponent] = [:]

    public init() {}

    /// Register a component under its `type`. Returns `self` for chaining.
    @discardableResult
    public func register(_ component: any MurtiComponent) -> MurtiComponentFactory {
        components[component.typeName] = component
        return self
    }

    /// Register a component with an inline builder — the one-line way to wrap any
    /// third-party library (or a one-off view) without declaring a type or a
    /// module. The same registry, same render path, same Null-Object fallback.
    @discardableResult
    public func register<Content: View>(
        _ type: String,
        @ViewBuilder makeView: @escaping @MainActor (_ node: MurtiNode, _ context: MurtiRenderContext) -> Content
    ) -> MurtiComponentFactory {
        components[type] = ClosureComponent { node, context in AnyView(makeView(node, context)) }
        return self
    }

    /// The component for a type, or `nil` if none is registered (the renderer
    /// then falls back to the Null Object).
    public func component(for type: String) -> (any MurtiComponent)? {
        components[type]
    }

    /// Registered type strings, sorted (handy for gallery/tests).
    public var registeredTypes: [String] { components.keys.sorted() }
}

/// A component whose view comes from an inline closure (the closure form of
/// `MurtiComponentFactory.register`). It is keyed directly by the registered
/// type, so its own `type` is unused.
private struct ClosureComponent: MurtiComponent {
    static let type = ""
    let body: @MainActor (MurtiNode, MurtiRenderContext) -> AnyView
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView { body(node, context) }
}

public extension MurtiComponentFactory {
    /// A factory pre-loaded with the built-in component set.
    static var withBuiltins: MurtiComponentFactory {
        MurtiComponentFactory()
            .register(TextComponent())
            .register(ImageComponent())
            .register(VStackComponent())
            .register(HStackComponent())
            .register(ButtonComponent())
            .register(CardComponent())
    }
}
