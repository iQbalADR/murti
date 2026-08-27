import SwiftUI
import MurtiCore

/// Edits the props of the selected node, plus move/delete. Each change rebuilds the
/// node and calls `document.replace`.
struct InspectorView: View {
    @Bindable var document: EditorDocument

    var body: some View {
        Group {
            if let id = document.selection, let node = document.root.find(id) {
                Form {
                    Section("Node") { LabeledContent("Type", value: node.type) }
                    Section("Properties") { propertyFields(node: node, id: id) }
                    Section {
                        Button("Move up") { document.move(id, by: -1) }
                        Button("Move down") { document.move(id, by: 1) }
                        Button("Delete", role: .destructive) { document.delete(id) }
                    }
                }
            } else {
                ContentUnavailableView("No selection", systemImage: "square.dashed")
            }
        }
        .navigationTitle("Inspector")
    }

    @ViewBuilder
    private func propertyFields(node: MurtiNode, id: String) -> some View {
        switch node.type {
        case "text":
            TextField("Value", text: stringBinding(id, "value"))
            Picker("Style", selection: stringBinding(id, "style")) {
                Text("body").tag("body")
                Text("title").tag("title")
                Text("headline").tag("headline")
                Text("caption").tag("caption")
            }
        case "button":
            TextField("Title", text: stringBinding(id, "title"))
        case "image":
            TextField("System name", text: stringBinding(id, "systemName"))
            TextField("Name", text: stringBinding(id, "name"))
        case "vstack", "hstack":
            TextField("Spacing", value: numberBinding(id, "spacing"), format: .number)
        case "card":
            TextField("Padding", value: numberBinding(id, "padding"), format: .number)
        default:
            ForEach(node.props.keys.sorted(), id: \.self) { key in
                TextField(key, text: stringBinding(id, key))
            }
        }
    }

    private func stringBinding(_ id: String, _ key: String) -> Binding<String> {
        Binding(get: { document.root.find(id)?.string(key) ?? "" },
                set: { setProp(id, key, .string($0)) })
    }
    private func numberBinding(_ id: String, _ key: String) -> Binding<Double> {
        Binding(get: { document.root.find(id)?.double(key) ?? 0 },
                set: { setProp(id, key, .number($0)) })
    }
    private func setProp(_ id: String, _ key: String, _ value: MurtiValue) {
        guard let node = document.root.find(id) else { return }
        var props = node.props
        props[key] = value
        document.replace(id, with: MurtiNode(id: node.id, type: node.type, props: props,
                                             children: node.children, action: node.action))
    }
}
