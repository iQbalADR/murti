import Foundation
import MurtiCore
import MurtiBuilder
import Observation

/// The editable screen: a `MurtiNode` tree where every node has an id, the current
/// selection, and undo history. Views observe it and call its edit methods.
@MainActor @Observable
final class EditorDocument {
    private(set) var key: String
    private(set) var root: MurtiNode
    var selection: String?

    private var undoStack: [MurtiNode] = []
    private var redoStack: [MurtiNode] = []

    init(key: String = "screen", root: MurtiNode = MurtiNode(type: "vstack")) {
        self.key = key
        self.root = root.withEnsuredIDs()
    }

    private func mutate(_ transform: (MurtiNode) -> MurtiNode) {
        let next = transform(root)
        guard next != root else { return }   // a no-op edit must not touch undo/redo history
        undoStack.append(root)
        redoStack.removeAll()
        root = next
    }

    func insert(_ child: MurtiNode, into parentID: String) {
        mutate { $0.insertingChild(child.withEnsuredIDs(), into: parentID) }
    }
    func delete(_ id: String) {
        mutate { $0.removing(id) }
        if selection == id { selection = nil }
    }
    func move(_ id: String, by delta: Int) { mutate { $0.movingChild(id, by: delta) } }
    func replace(_ id: String, with node: MurtiNode) { mutate { $0.replacing(id, with: node) } }

    /// Replace the document with the decoded payload, assigning editor ids.
    func importJSON(_ data: Data) throws {
        let payload = try JSONDecoder().decode(MurtiPayload.self, from: data)
        undoStack.append(root)
        redoStack.removeAll()
        key = payload.screen.key
        root = payload.screen.root.withEnsuredIDs()
        selection = nil
    }

    /// Validated JSON of the current tree, with all node ids stripped for clean
    /// output. The editor cannot tell authored ids apart from the UUIDs it assigns,
    /// so any id present in the imported JSON is not preserved on export.
    func exportJSON(validator: MurtiSchemaValidator = MurtiSchemaValidator()) throws -> Data {
        let payload = MurtiPayload(schemaVersion: "1.0",
                                   screen: MurtiScreenSpec(key: key, root: root.strippingIDs()))
        try validator.validate(payload)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return try encoder.encode(payload)
    }

    /// MurtiBuilder DSL source for the current tree. Node ids aren't emitted (the
    /// DSL doesn't set them), matching JSON export.
    func exportDSLSource() -> String {
        DSLExport.source(forScreen: key, root: root)
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(root)
        root = previous
    }
    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(root)
        root = next
    }
}
