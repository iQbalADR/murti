import SwiftUI

/// The editor shell: outline on the left, live preview in the middle, inspector on
/// the right.
struct StudioView: View {
    @State private var document = EditorDocument()

    var body: some View {
        NavigationSplitView {
            OutlineView(document: document)
                .navigationTitle("Outline")
        } content: {
            PreviewView(document: document)
        } detail: {
            InspectorView(document: document)
        }
    }
}
