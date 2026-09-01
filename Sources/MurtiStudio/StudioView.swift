import SwiftUI

/// The editor shell: outline on the left, live preview in the middle, inspector on
/// the right, with import/export/undo in the toolbar.
struct StudioView: View {
    @State private var document = EditorDocument()
    @State private var importText = ""
    @State private var showImport = false
    @State private var exportText = ""
    @State private var showExport = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationSplitView {
            OutlineView(document: document)
                .navigationTitle("Outline")
        } content: {
            PreviewView(document: document)
        } detail: {
            InspectorView(document: document)
        }
        .toolbar {
            ToolbarItemGroup {
                Button { document.undo() } label: { Label("Undo", systemImage: "arrow.uturn.backward") }
                    .disabled(!document.canUndo)
                Button { document.redo() } label: { Label("Redo", systemImage: "arrow.uturn.forward") }
                    .disabled(!document.canRedo)
                Button("Import") { importText = ""; showImport = true }
                Button("Export") { runExport() }
                Button("Export DSL") { exportText = document.exportDSLSource(); showExport = true }
            }
        }
        .sheet(isPresented: $showImport) {
            JSONSheet(title: "Paste JSON", text: $importText, action: "Load", onAction: runImport)
        }
        .sheet(isPresented: $showExport) {
            JSONSheet(title: "Exported JSON", text: .constant(exportText), action: "Done") { showExport = false }
        }
        .alert("Error", isPresented: errorAlertBinding) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func runImport() {
        do {
            try document.importJSON(Data(importText.utf8))
            showImport = false
        } catch {
            errorMessage = "\(error)"
        }
    }

    private func runExport() {
        do {
            exportText = String(decoding: try document.exportJSON(), as: UTF8.self)
            showExport = true
        } catch {
            errorMessage = "\(error)"
        }
    }
}

/// A monospaced text sheet used for both pasting JSON to import and showing exported
/// JSON to copy.
private struct JSONSheet: View {
    let title: String
    @Binding var text: String
    let action: String
    let onAction: () -> Void

    var body: some View {
        NavigationStack {
            TextEditor(text: $text)
                .font(.system(.footnote, design: .monospaced))
                .padding()
                .navigationTitle(title)
                .toolbar { Button(action, action: onAction) }
        }
    }
}
