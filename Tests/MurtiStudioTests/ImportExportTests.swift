import Foundation
import Testing
import MurtiCore
@testable import MurtiStudio

@MainActor
@Suite("Import/export")
struct ImportExportTests {
    @Test func importThenExportRoundTrips() throws {
        let json = Data(#"{"schemaVersion":"1.0","screen":{"key":"home","root":{"type":"vstack","children":[{"type":"text","props":{"value":"hi"}}]}}}"#.utf8)
        let d = EditorDocument()
        try d.importJSON(json)
        #expect(d.key == "home")
        #expect(d.root.children[0].string("value") == "hi")
        // Export strips editor ids and validates.
        let out = try d.exportJSON()
        let payload = try JSONDecoder().decode(MurtiPayload.self, from: out)
        #expect(payload.screen.key == "home")
        #expect(payload.screen.root.id == nil)             // ids stripped
        #expect(payload.screen.root.children[0].string("value") == "hi")
    }
    @Test func exportRejectsInvalidTree() {
        let d = EditorDocument(root: MurtiNode(type: "button",
            action: MurtiActionSpec(type: .openURL, link: "https://evil.example.com")))
        #expect(throws: MurtiError.self) { try d.exportJSON() }
    }
}
