import SwiftUI
import MurtiCore

/// Renders the current tree with the real renderer, so the editor shows exactly
/// what the framework would render.
struct PreviewView: View {
    let document: EditorDocument

    var body: some View {
        let renderer = MurtiRenderer(factory: .withBuiltins)
        return ScrollView {
            renderer.render(document.root, data: DataContext())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
        .navigationTitle("Preview")
    }
}
