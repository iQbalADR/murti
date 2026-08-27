import Testing
import MurtiCore
@testable import MurtiStudio

@Suite("Node tree edits")
struct NodeTreeTests {
    private var tree: MurtiNode {
        MurtiNode(id: "root", type: "vstack", children: [
            MurtiNode(id: "a", type: "text", props: ["value": "a"]),
            MurtiNode(id: "b", type: "vstack", children: [MurtiNode(id: "c", type: "text")]),
        ])
    }
    @Test func findsByID() {
        #expect(tree.find("c")?.type == "text")
        #expect(tree.find("missing") == nil)
    }
    @Test func replacesByID() {
        let updated = tree.replacing("a", with: MurtiNode(id: "a", type: "text", props: ["value": "Z"]))
        #expect(updated.find("a")?.string("value") == "Z")
    }
    @Test func removesByID() {
        let updated = tree.removing("c")
        #expect(updated.find("c") == nil)
        #expect(updated.find("b")?.children.isEmpty == true)
    }
}
