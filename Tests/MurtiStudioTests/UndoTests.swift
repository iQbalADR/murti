import Testing
import MurtiCore
@testable import MurtiStudio

@MainActor
@Suite("Undo/redo")
struct UndoTests {
    @Test func undoRedoRestoresTree() {
        let d = EditorDocument(root: MurtiNode(id: "root", type: "vstack"))
        #expect(d.canUndo == false)
        d.insert(MurtiNode(id: "x", type: "text"), into: "root")
        #expect(d.root.children.count == 1)
        #expect(d.canUndo == true)
        d.undo()
        #expect(d.root.children.isEmpty)
        #expect(d.canRedo == true)
        d.redo()
        #expect(d.root.children.count == 1)
    }
    @Test func editClearsRedo() {
        let d = EditorDocument(root: MurtiNode(id: "root", type: "vstack"))
        d.insert(MurtiNode(id: "x", type: "text"), into: "root")
        d.undo()
        d.insert(MurtiNode(id: "y", type: "text"), into: "root")   // new edit
        #expect(d.canRedo == false)
    }
    @Test func noOpEditLeavesHistoryUntouched() {
        let d = EditorDocument(root: MurtiNode(id: "root", type: "vstack",
            children: [MurtiNode(id: "a", type: "text"), MurtiNode(id: "b", type: "text")]))
        d.insert(MurtiNode(id: "x", type: "text"), into: "root")
        d.undo()                       // canUndo == false, canRedo == true
        d.move("a", by: -1)            // no-op: "a" is already first
        #expect(d.canRedo == true)     // redo not wiped by a no-op
        #expect(d.canUndo == false)    // no phantom undo entry
    }
}
