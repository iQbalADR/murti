import SwiftUI

/// A single component (Pattern B): one small type per JSON `type`, added to the
/// one `MurtiComponentFactory`. This is what makes "add a component = one file,
/// one PR" true, and lets third-party modules self-register.
///
/// `@MainActor` because `makeView` builds SwiftUI views.
@MainActor
public protocol MurtiComponent {
    /// The JSON `type` string this component renders.
    static var type: String { get }
    /// Build the view for a node. Reads props from the node and resolves dynamic
    /// values (`{{token}}`) via the context.
    func makeView(_ node: MurtiNode, context: MurtiRenderContext) -> AnyView
}

public extension MurtiComponent {
    /// Instance-side access to the registered type string.
    var typeName: String { Self.type }
}
