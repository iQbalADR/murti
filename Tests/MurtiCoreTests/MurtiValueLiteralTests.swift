import Testing
@testable import MurtiCore

@Suite("MurtiValue literals")
struct MurtiValueLiteralTests {
    @Test func scalarLiterals() {
        #expect(("hi" as MurtiValue) == .string("hi"))
        #expect((4 as MurtiValue) == .number(4))
        #expect((1.5 as MurtiValue) == .number(1.5))
        #expect((true as MurtiValue) == .bool(true))
    }
    @Test func collectionLiterals() {
        #expect(([1, 2] as MurtiValue) == .array([.number(1), .number(2)]))
        #expect((["a": 1] as MurtiValue) == .object(["a": .number(1)]))
    }
    @Test func propsBagUsesLiterals() {
        let props: [String: MurtiValue] = ["stars": 4, "label": "x", "on": true]
        #expect(props["stars"] == .number(4))
        #expect(props["label"] == .string("x"))
        #expect(props["on"] == .bool(true))
    }
}
