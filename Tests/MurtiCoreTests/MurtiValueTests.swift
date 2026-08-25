import Foundation
import Testing
@testable import MurtiCore

@Suite("MurtiValue")
struct MurtiValueTests {
    @Test("decodes each JSON kind")
    func decodesAll() throws {
        let json = Data("""
        { "s": "hi", "n": 12, "f": 1.5, "b": true, "z": null,
          "a": [1, "two", false], "o": { "k": "v" } }
        """.utf8)
        let dict = try JSONDecoder().decode([String: MurtiValue].self, from: json)
        #expect(dict["s"] == .string("hi"))
        #expect(dict["n"] == .number(12))
        #expect(dict["f"] == .number(1.5))
        #expect(dict["b"] == .bool(true))
        #expect(dict["z"] == .null)
        #expect(dict["a"] == .array([.number(1), .string("two"), .bool(false)]))
        #expect(dict["o"] == .object(["k": .string("v")]))
    }

    @Test("typed accessors")
    func accessors() {
        #expect(MurtiValue.string("x").stringValue == "x")
        #expect(MurtiValue.number(3).intValue == 3)
        #expect(MurtiValue.number(3.9).intValue == 3)
        #expect(MurtiValue.bool(true).boolValue == true)
        #expect(MurtiValue.string("x").intValue == nil)
    }

    @Test("displayString for interpolation")
    func display() {
        #expect(MurtiValue.number(12).displayString == "12")
        #expect(MurtiValue.number(1.5).displayString == "1.5")
        #expect(MurtiValue.string("hi").displayString == "hi")
        #expect(MurtiValue.bool(false).displayString == "false")
        #expect(MurtiValue.null.displayString == "")
    }

    @Test("round-trips through JSON")
    func roundTrip() throws {
        let value = MurtiValue.object([
            "a": .array([.number(1), .string("two")]),
            "b": .bool(true),
            "c": .null,
        ])
        let data = try JSONEncoder().encode(value)
        #expect(try JSONDecoder().decode(MurtiValue.self, from: data) == value)
    }
}
