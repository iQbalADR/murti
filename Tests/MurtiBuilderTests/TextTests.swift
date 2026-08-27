import Testing
import MurtiCore
@testable import MurtiBuilder

@Suite("Text builder")
struct TextTests {
    @Test func plainText() {
        #expect(Text("hi").node() == MurtiNode(type: "text", props: ["value": "hi"]))
    }
    @Test func styledText() {
        let n = Text("Title", style: .title).node()
        #expect(n.type == "text")
        #expect(n.string("value") == "Title")
        #expect(n.string("style") == "title")
    }
}
