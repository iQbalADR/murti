import SwiftUI

/// Walks a `MurtiNode` tree (Composite) and interprets it into SwiftUI views.
/// A thin entry point: it seeds the root `MurtiRenderContext`, which carries the
/// recursion and the Null-Object fallback.
@MainActor
public struct MurtiRenderer {
    public let factory: MurtiComponentFactory

    public init(factory: MurtiComponentFactory) {
        self.factory = factory
    }

    /// Render a node tree into a SwiftUI view.
    public func render(
        _ node: MurtiNode,
        data: DataContext = DataContext(),
        dispatch: @escaping @MainActor (MurtiActionSpec) -> Void = { _ in }
    ) -> AnyView {
        let context = MurtiRenderContext(data: data, factory: factory, dispatch: dispatch)
        return context.view(for: node)
    }
}
