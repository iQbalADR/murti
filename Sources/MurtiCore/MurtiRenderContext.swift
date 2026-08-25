import SwiftUI

/// Everything a component needs to render, plus the glue: the data context, token
/// resolution, action dispatch, child scoping, and Composite recursion.
@MainActor
public struct MurtiRenderContext {
    public let data: DataContext
    public let factory: MurtiComponentFactory
    public let dispatch: @MainActor (MurtiActionSpec) -> Void

    public init(
        data: DataContext,
        factory: MurtiComponentFactory = MurtiComponentFactory(),
        dispatch: @escaping @MainActor (MurtiActionSpec) -> Void = { _ in }
    ) {
        self.data = data
        self.factory = factory
        self.dispatch = dispatch
    }

    /// Interpolate `{{token}}`s against the data context.
    public func resolve(_ template: String) -> String { data.resolve(template) }

    /// A scoped context for children / list rows: a fresh `DataContext` seeded
    /// from this one plus `extra`, so a row's tokens never leak into the parent.
    public func child(merging extra: [String: MurtiValue]) -> MurtiRenderContext {
        let scoped = DataContext(data.snapshot.merging(extra) { _, new in new })
        return MurtiRenderContext(data: scoped, factory: factory, dispatch: dispatch)
    }

    /// Resolve a node to its view: Composite recursion, with the Null-Object
    /// fallback for any unregistered type — never a crash.
    public func view(for node: MurtiNode) -> AnyView {
        if let component = factory.component(for: node.type) {
            return component.makeView(node, context: self)
        }
        return AnyView(MurtiUnknownView(type: node.type))
    }
}
