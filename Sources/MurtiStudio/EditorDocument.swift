import MurtiCore
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
        undoStack.append(root)
        redoStack.removeAll()
        root = transform(root)
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
}
