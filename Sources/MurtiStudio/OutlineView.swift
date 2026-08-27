import SwiftUI
import MurtiCore

/// The node tree as a selectable, nestable outline.
struct OutlineView: View {
    @Bindable var document: EditorDocument

    var body: some View {
        List(selection: $document.selection) {
            OutlineGroup([document.root], id: \.editorID, children: \.outlineChildren) { node in
                Text(node.outlineLabel).tag(node.editorID)
            }
        }
    }
}
