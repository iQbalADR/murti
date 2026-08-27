import Testing
import MurtiCore
@testable import MurtiBuilder

@Suite("Stacks")
struct StackTests {
    @Test func vstackWithChildren() {
        let n = VStack(spacing: 12, alignment: .leading) {
            Text("a")
            Text("b")
        }.node()
        #expect(n.type == "vstack")
        #expect(n.int("spacing") == 12)
        #expect(n.string("alignment") == "leading")
        #expect(n.children.count == 2)
        #expect(n.children[0].string("value") == "a")
    }
    @Test func hstackDefaults() {
        let n = HStack { Text("x") }.node()
        #expect(n.type == "hstack")
        #expect(n.children.count == 1)
        #expect(n.props["spacing"] == nil)   // omitted when unset
    }
    @Test func ifAndForInBuilder() {
        let show = true
        let n = VStack {
            if show { Text("shown") }
            for word in ["a", "b"] { Text(word) }
        }.node()
        #expect(n.children.count == 3)
    }
}
