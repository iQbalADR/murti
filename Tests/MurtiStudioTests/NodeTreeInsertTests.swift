import Testing
import MurtiCore
@testable import MurtiStudio

@Suite("Node tree insert/move/ids")
struct NodeTreeInsertTests {
    private var tree: MurtiNode {
        MurtiNode(id: "root", type: "vstack", children: [
            MurtiNode(id: "a", type: "text"), MurtiNode(id: "b", type: "text"),
        ])
    }
    @Test func insertsChild() {
        let updated = tree.insertingChild(MurtiNode(id: "x", type: "text"), into: "root")
        #expect(updated.children.map(\.id) == ["a", "b", "x"])
    }
    @Test func movesChild() {
        let updated = tree.movingChild("b", by: -1)
        #expect(updated.children.map(\.id) == ["b", "a"])
    }
    @Test func moveOutOfBoundsIsNoOp() {
        #expect(tree.movingChild("a", by: -1).children.map(\.id) == ["a", "b"])
    }
    @Test func ensuresIDsWhereMissing() {
        let bare = MurtiNode(type: "vstack", children: [MurtiNode(type: "text")])
        let withIDs = bare.withEnsuredIDs()
        #expect(withIDs.id != nil)
        #expect(withIDs.children[0].id != nil)
    }
    @Test func preservesExistingIDs() {
        #expect(tree.withEnsuredIDs().id == "root")
        #expect(tree.withEnsuredIDs().children[0].id == "a")
    }
    @Test func stripsIDs() {
        #expect(tree.strippingIDs().id == nil)
        #expect(tree.strippingIDs().children.allSatisfy { $0.id == nil })
    }
}
