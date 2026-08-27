import SwiftUI
import MurtiCore

/// An "Add" menu that inserts a new component into the selected container (or the
/// root when the selection isn't a container).
struct PaletteView: View {
    let document: EditorDocument
    private let types = ["text", "vstack", "hstack", "button", "image", "card"]

    var body: some View {
        Menu {
            ForEach(types, id: \.self) { type in
                Button(type) { document.insert(MurtiNode(type: type), into: insertionParent) }
            }
        } label: {
            Label("Add", systemImage: "plus")
        }
    }

    private var insertionParent: String {
        let containers = ["vstack", "hstack", "card"]
        if let id = document.selection, let node = document.root.find(id), containers.contains(node.type) {
            return id
        }
        return document.root.editorID
    }
}
