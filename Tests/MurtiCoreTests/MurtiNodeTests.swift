import Foundation
import Testing
@testable import MurtiCore

@Suite("MurtiNode")
struct MurtiNodeTests {
    @Test("decodes type, props, children, action")
    func decodes() throws {
        let json = Data("""
        { "type": "vstack", "props": { "spacing": 12 },
          "children": [ { "type": "text", "props": { "value": "hi" } } ],
          "action": { "type": "refresh" } }
        """.utf8)
        let node = try JSONDecoder().decode(MurtiNode.self, from: json)
        #expect(node.type == "vstack")
        #expect(node.int("spacing") == 12)
        #expect(node.children.count == 1)
        #expect(node.children[0].string("value") == "hi")
        #expect(node.action?.type == .refresh)
        #expect(node.id == nil)
    }

    @Test("id is preserved when present")
    func idPresent() throws {
        let node = try JSONDecoder().decode(MurtiNode.self, from: Data(#"{ "id": "n1", "type": "text" }"#.utf8))
        #expect(node.id == "n1")
    }

    @Test("missing type is rejected at the structural layer")
    func missingType() {
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MurtiNode.self, from: Data(#"{ "props": {} }"#.utf8))
        }
    }

    @Test("defaulting accessors never throw on missing props")
    func defaults() {
        let node = MurtiNode(type: "text")
        #expect(node.string("missing") == "")
        #expect(node.int("missing") == 0)
        #expect(node.bool("missing") == false)
        #expect(node.array("missing").isEmpty)
    }

    @Test("round-trips through JSON")
    func roundTrip() throws {
        let node = MurtiNode(
            type: "button",
            props: ["title": .string("Go")],
            action: MurtiActionSpec(type: .navigate, screen: "next")
        )
        let data = try JSONEncoder().encode(node)
        #expect(try JSONDecoder().decode(MurtiNode.self, from: data) == node)
    }
}
