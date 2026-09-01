import Testing
import MurtiCore
@testable import MurtiBuilder

@Suite("DSL export")
struct DSLExportTests {
    @Test func textWithStyle() {
        let n = Text("Hello", style: .title).node()
        #expect(DSLExport.source(for: n) == #"Text("Hello", style: .title)"#)
    }

    @Test func plainText() {
        let n = Text("Hi").node()
        #expect(DSLExport.source(for: n) == #"Text("Hi")"#)
    }

    @Test func verticalStackWithChildren() {
        let n = VStack(spacing: 12, alignment: .leading) {
            Text("A")
            Text("B", style: .caption)
        }.node()
        let expected = """
        VStack(spacing: 12, alignment: .leading) {
            Text("A")
            Text("B", style: .caption)
        }
        """
        #expect(DSLExport.source(for: n) == expected)
    }

    @Test func emptyStack() {
        let n = HStack { }.node()
        #expect(DSLExport.source(for: n) == "HStack {\n}")
    }

    @Test func buttonWithNavigateAndParams() {
        let n = Button("Go", action: .navigate("detail", params: ["id": "1"])).node()
        #expect(DSLExport.source(for: n) == #"Button("Go", action: .navigate("detail", params: ["id": "1"]))"#)
    }

    @Test func buttonWithApiChain() {
        let n = Button("Load", action: .api("getBalance", onSuccess: .navigate("balance"))).node()
        #expect(DSLExport.source(for: n)
            == #"Button("Load", action: .api("getBalance", onSuccess: .navigate("balance")))"#)
    }

    @Test func dismissButton() {
        let n = Button("Close", action: .dismiss).node()
        #expect(DSLExport.source(for: n) == #"Button("Close", action: .dismiss)"#)
    }

    @Test func systemImage() {
        let n = Image(systemName: "star.fill").node()
        #expect(DSLExport.source(for: n) == #"Image(systemName: "star.fill")"#)
    }

    @Test func namedImageWithContentMode() {
        let n = Image(name: "hero", contentMode: "fill").node()
        #expect(DSLExport.source(for: n) == #"Image(name: "hero", contentMode: "fill")"#)
    }

    @Test func cardWithPadding() {
        let n = Card(padding: 20) { Text("Body") }.node()
        let expected = """
        Card(padding: 20) {
            Text("Body")
        }
        """
        #expect(DSLExport.source(for: n) == expected)
    }

    @Test func unknownTypeUsesComponentEscapeHatch() {
        let n = MurtiNode(type: "ext.lottie", props: ["name": .string("spinner"), "loop": .bool(true)])
        #expect(DSLExport.source(for: n) == #"component("ext.lottie", ["loop": true, "name": "spinner"])"#)
    }

    @Test func componentEncodesNestedValueLiterals() {
        let n = MurtiNode(type: "chart", props: [
            "series": .array([.number(1), .number(2.5)]),
            "meta": .object(["k": .string("v")]),
            "empty": .null,
        ])
        #expect(DSLExport.source(for: n)
            == #"component("chart", ["empty": .null, "meta": ["k": "v"], "series": [1, 2.5]])"#)
    }

    @Test func knownTypeWithExtraPropFallsBackToComponent() {
        // A text node carrying a prop the Text initializer can't express.
        let n = MurtiNode(type: "text", props: ["value": .string("Hi"), "weight": .string("bold")])
        #expect(DSLExport.source(for: n) == #"component("text", ["value": "Hi", "weight": "bold"])"#)
    }

    @Test func actionOnNonButtonIsNotedAndOmitted() {
        let n = MurtiNode(type: "card", props: [:], action: MurtiActionSpec(type: .refresh))
        let expected = """
        // note: an action on "card" isn't expressible in the DSL and was omitted
        component("card")
        """
        #expect(DSLExport.source(for: n) == expected)
    }

    @Test func screenWrapsRootAndIndents() {
        let payload = Screen("home") {
            VStack(spacing: 8) {
                Text("Title", style: .title)
                Button("Next", action: .navigate("second"))
            }
        }.payload
        let expected = """
        Screen("home") {
            VStack(spacing: 8) {
                Text("Title", style: .title)
                Button("Next", action: .navigate("second"))
            }
        }
        """
        #expect(DSLExport.source(for: payload) == expected)
    }

    @Test func screenIncludesNonDefaultSchemaVersion() {
        let payload = Screen("home", schemaVersion: "2.0") { Text("Hi") }.payload
        let expected = """
        Screen("home", schemaVersion: "2.0") {
            Text("Hi")
        }
        """
        #expect(DSLExport.source(for: payload) == expected)
    }
}
