import Testing
import MurtiCore
@testable import MurtiStudio

@MainActor
@Suite("EditorDocument")
struct EditorDocumentTests {
    private func doc() -> EditorDocument {
        EditorDocument(key: "s", root: MurtiNode(id: "root", type: "vstack",
            children: [MurtiNode(id: "a", type: "text"), MurtiNode(id: "b", type: "text")]))
    }
    @Test func insertsIntoContainer() {
        let d = doc()
        d.insert(MurtiNode(id: "x", type: "text"), into: "root")
        #expect(d.root.children.map(\.id) == ["a", "b", "x"])
    }
    @Test func deletesAndClearsSelection() {
        let d = doc(); d.selection = "a"
        d.delete("a")
        #expect(d.root.find("a") == nil)
        #expect(d.selection == nil)
    }
    @Test func movesAndReplaces() {
        let d = doc()
        d.move("b", by: -1)
        #expect(d.root.children.map(\.id) == ["b", "a"])
        d.replace("a", with: MurtiNode(id: "a", type: "text", props: ["value": "Z"]))
        #expect(d.root.find("a")?.string("value") == "Z")
    }
}
